# pylint: disable=import-error
'''
    Lambda Function to validate the role and attached policies on specified account
'''
from __future__ import print_function
import json
import os
import boto3

ROLE_NAME = ""
POLICY_NAME = ""
COMPLIANCE_ACCOUNT = ""

class LambdaException(Exception):
    """
    Description:this class is used for capturing all the exceptions
    """
    pass

def raise_exception(exception_type, message):
    ''' Function to throw the exception in custom format'''
    exception_type = exception_type
    exception_message = message
    api_exception_obj = {}
    api_exception_obj = {
        "isError": True,
        "type": exception_type,
        "message": exception_message
        }

    # Create a JSON string
    api_exception_json = json.dumps(api_exception_obj)
    raise LambdaException(api_exception_json)

def check_account(account_id):
    ''' Function to check if the account number is not empty and is digit '''
    if account_id is None:
        raise_exception(
            "ClientError",
            "Account Number is empty, please enter a valid account number",
            )
    elif not account_id.isdigit():
        raise_exception(
            "ClientError",
            "Please enter a valid account number, account number has to be 12 digit number",
            )
    elif len(account_id) != 12:
        raise_exception(
            "ClientError",
            "Please enter a valid account number, account number has to be 12 digit number",
            )

def check_compliance_account(account_id):
    ''' Function to check if the compliance account number is not empty and is digit '''
    if account_id is None:
        raise_exception(
            "ClientError",
            "Compliance Account number is empty, please enter a valid account number",
            )
    elif not account_id.isdigit():
        raise_exception(
            "ClientError",
            "Enter a valid compliance account number, it has to be 12 digit number",
            )
    elif len(account_id) != 12:
        raise_exception(
            "ClientError",
            "Enter a valid compliance account number, it has to be 12 digit number",
            )

def compare_policy(policies_from_document, policies_from_aws):
    '''function to check if the required policies are present'''
    for policy in policies_from_document:
        if policy in policies_from_aws:
            check = True
        else:
            print("ERROR: " + policy + " is not present in policy")
            return False
    return check

def check_assume_role(sts_client, duration, role_arn, session_name):
    '''function to check if principal is able to assume the role '''
    sts_response = {}
    try:
        sts_response = sts_client.assume_role(DurationSeconds=duration,
                                              RoleArn=role_arn,
                                              RoleSessionName=session_name)
        if sts_response['ResponseMetadata']['HTTPStatusCode'] == 200:
            print("INFO: Able to assume read role...")
    except Exception as err:
        exception_type = err.__class__.__name__
        exception_message = err.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)
    return sts_response, True

def check_trust_policy(sts_creds, role_name, principal_role_arn):
    '''function to check if the required trust policies are present'''
    try:
        iam = boto3.client('iam',
                           aws_access_key_id=sts_creds['AccessKeyId'],
                           aws_secret_access_key=sts_creds['SecretAccessKey'],
                           aws_session_token=sts_creds['SessionToken'])
        role_resp = iam.get_role(RoleName=role_name)
    except Exception as err:
        exception_type = err.__class__.__name__
        exception_message = "Failed to validate trust policy for role "+ role_name +" :"+err.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)

    policy_statements = role_resp['Role']['AssumeRolePolicyDocument']['Statement']

    try:
        next(stmt for stmt in policy_statements if principal_role_arn in stmt['Principal']['AWS'] and stmt['Action'] == 'sts:AssumeRole' and stmt['Effect'] == 'Allow')
        print("INFO: Associated trust relationship found...")
    except Exception as err:
        exception_type = err.__class__.__name__
        exception_message = "Failed to validate trust policy for role "+role_name+" :"+err.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)
    return True

def check_managed_policy(sts_creds, policy_doc):
    '''function to validate the managed policies atached with the role'''
    try:
        iam = boto3.client('iam',
                           aws_access_key_id=sts_creds['AccessKeyId'],
                           aws_secret_access_key=sts_creds['SecretAccessKey'],
                           aws_session_token=sts_creds['SessionToken'])
        managed_policies = iam.list_attached_role_policies(RoleName=ROLE_NAME)
    except Exception as err:
        exception_type = err.__class__.__name__
        exception_message = "Failed to validate managed policy for role "+ROLE_NAME+" :"+err.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)

    attached_policies = managed_policies['AttachedPolicies']

    try:
        splunk_policy = next(stmt for stmt in attached_policies if stmt['PolicyName'] == POLICY_NAME)
    except Exception as err:
        exception_type = err.__class__.__name__
        exception_message = "Failed to validate managed policy for role "+ROLE_NAME+" :"+err.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)

    try:
        policy_info = iam.get_policy(PolicyArn=splunk_policy['PolicyArn'])
        account_policy = iam.get_policy_version(PolicyArn=splunk_policy['PolicyArn'],
                                                VersionId=policy_info['Policy']['DefaultVersionId'])
    except Exception as err:
        exception_type = err.__class__.__name__
        exception_message = "Failed to validate managed policy for role "+ROLE_NAME+" :"+err.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)

    policy_statements = account_policy['PolicyVersion']['Document']['Statement']
    account_policy_actions = [action for stmt in policy_statements for action in stmt['Action']]
    return compare_policy(policy_doc, account_policy_actions)

def result_json(status, message, assume_role_status, trust_policy_status, policy_status):
    '''helper function to construct and return the output in json format'''
    result = {}
    result['data'] = {}
    result['status'] = status
    result['message'] = message
    result['data']['assumerole'] = assume_role_status
    result['data']['attachedpolicy'] = policy_status
    result['data']['trustpolicy'] = trust_policy_status
    return result

def lambda_handler(event, context):
    '''
    lambda_handler receives an account_id as event data and tries to assume the ROLE_NAME role
    on the cross account specified in account_id to evaluate the ROLE_NAME role on cross account
    During the process it generates the temproary credentials to access the cross account resources.
    This function validates the POLICY_NAME and trusted principal attached to the ROLE_NAME
    and returns the outcome of the validation as json object to the gateway
    '''
    account_id = event.get('account_id')
    global ROLE_NAME, POLICY_NAME, COMPLIANCE_ACCOUNT
    ROLE_NAME = event.get("role_name", "tesco-app-compliance")
    POLICY_NAME = event.get("policy_name", "tesco-app-compliance")
    COMPLIANCE_ACCOUNT = event.get("compliance_account", "264005623395")
    check_account(account_id)
    check_compliance_account(COMPLIANCE_ACCOUNT)
    rolearn = 'arn:aws:iam::' + event['account_id'] + ':role/' + ROLE_NAME
    compliancearn = 'arn:aws:iam::' + COMPLIANCE_ACCOUNT + ':root'

    try:
        policyjson = json.load(open("./policies/" + ROLE_NAME + "/"+ POLICY_NAME + '.json'))
    except Exception as err:
        print("ERROR: Failed to load policy json document")
        raise_exception(err.__class__.__name__, "Failed to load policy json document")

    policydoc = [action for statement in policyjson['Statement'] for action in statement['Action']]
    stsclient = boto3.client('sts')

    print("INFO: Attempting to assume the role: " + rolearn)
    stsresponse, assumestatus = check_assume_role(stsclient, 900, rolearn, 'splunk_session')
    if not assumestatus:
        print("ERROR: Unable to assume role, exiting ....")
        raise_exception("ClientError", "Failed to assume role, validate the lambda role permissions")

    print("INFO: Getting trust relationships associated with " + rolearn)
    trustpolicy = check_trust_policy(stsresponse['Credentials'], ROLE_NAME, compliancearn)
    if not trustpolicy:
        print("ERROR: Trust relationship not found, exiting ....")
        return result_json(False, "Trust relationship not found", assumestatus, False, False)

    print("INFO: Comparing account managed policies associated with " + rolearn)
    policystatus = check_managed_policy(stsresponse['Credentials'], policydoc)
    if not policystatus:
        print("ERROR: Invalid managed policy attached to the role, exiting ....")
        return result_json(False, "Role managed policy validation failed", assumestatus, trustpolicy, False)
    print("INFO: All checks passed...")
    return result_json(True, "role and attached policies are valid on the account", assumestatus, trustpolicy, policystatus)
