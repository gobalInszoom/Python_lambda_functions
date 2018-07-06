# pylint: disable=import-error
'''
    Lambda Function to Provision the Compliance IAM role and associated IAM Policy on the specified account
'''
from __future__ import print_function
import json
import os
import boto3
from botocore.exceptions import ClientError

# Read config variables from environment, fall back to defaults
ROLE_NAME = os.environ.get("ROLE_NAME", "tesco-app-compliance")
POLICY_NAME = os.environ.get("POLICY_NAME", "tesco-app-compliance")

class LambdaException(Exception):
    """
    Description:this class is used for capturing all the exceptions
    """
    pass

def raise_exception(error_type, error_message):
    """
    This function is to wraps error type and error message as exception
    """
    api_exception_obj = {
        "isError": True,
        "type": error_type,
        "message": error_message
    }
    api_exception_json = json.dumps(api_exception_obj)
    raise LambdaException(api_exception_json)

def validate_credentials(account_id, access_key, secret_key, session_token):
    '''function to validate the aws account id and credentials supplied  via the lambda event'''
    if any(arg is None for arg in [account_id, access_key, secret_key]):
        print("ERROR: Invalid Credentials supplied")
        raise_exception("ClientError", "Invalid account ID or credentials supplied, please check whether the account ID or supplied credentials are valid")

    if not account_id.isdigit() or len(account_id) != 12:
        print("ERROR: Invalid Account ID supplied")
        raise_exception("ClientError", "Invalid account id supplied, please check whether the account ID is valid. It should be 12 digits")

    sts_client = boto3.client(
        'sts',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token
    )

    try:
        caller_account_id = sts_client.get_caller_identity()['Account']
        print("INFO: Caller Account ID: " + caller_account_id)
    except ClientError as err:
        print("ERROR: Failed to get caller identity")
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__, "Failed to get caller identity: " + err.message)

    if caller_account_id != account_id:
        print("ERROR: Mismatch of account ID and credentials supplied")
        raise_exception("ClientError", "Invalid account ID or credentials supplied")

def create_policy(iam_client, policy_doc):
    """
    This function is to wraps boto3 iam create_policy method with error handling
    """
    try:
        new_policy = iam_client.create_policy(
            PolicyName=POLICY_NAME,
            PolicyDocument=json.dumps(policy_doc)
        )
        print("INFO: Created policy " + new_policy['Policy']['Arn'])
    except ClientError as err:
        print("ERROR: Failed to create " + POLICY_NAME + " policy")
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__, "Failed to create " + POLICY_NAME + " policy: " + err.message)
    return 1, "v1"

def create_policy_version(iam_client, policy_vers, policy_arn, policy_doc):
    """
    This function is to wraps boto3 iam create_policy_version and delete_policy attach_role_policy methods with error handling
    and provides a way to create new policy version by deleting oldest version when maximum policy versions are present
    """
    num_vers = len(policy_vers) if policy_vers else 0

    if num_vers == 5:
        print("INFO: Maximum versions of the " + POLICY_NAME + " policy already exist, attempting tp delete oldest version.")
        try:
            iam_client.delete_policy_version(
                PolicyArn=policy_arn,
                VersionId=policy_vers[4]
            )
            num_vers = num_vers - 1
            print("INFO: Deleted " + policy_vers[4] + " version of the " + POLICY_NAME + " policy")
        except ClientError as err:
            print("ERROR: Failed to delete " + policy_vers[4] + " version of the " + POLICY_NAME + " policy")
            print("ERROR: " + err.message)
            raise_exception(err.__class__.__name__, "Failed to delete old policy version: " + err.message)

    try:
        new_policy = iam_client.create_policy_version(
            PolicyArn=policy_arn,
            PolicyDocument=json.dumps(policy_doc),
            SetAsDefault=True
        )
        num_vers = num_vers + 1
        current_policy = new_policy['PolicyVersion']['VersionId']
        print("INFO: Created " + new_policy['PolicyVersion']['VersionId'] + " version of the " + POLICY_NAME + " policy")
    except ClientError as err:
        print("ERROR: Failed to create new policy version")
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__, "Failed to create new policy version: " + err.message)
    return num_vers, current_policy

def attach_role_policy(iam_client, policy_arn):
    """
    This function is to wraps the boto3 iam attach_role_policy method with error handling
    """
    try:
        iam_client.attach_role_policy(RoleName=ROLE_NAME, PolicyArn=policy_arn)
        print("INFO: Successfully attached " + POLICY_NAME + " policy with " + ROLE_NAME + " role")
    except ClientError as err:
        print("ERROR: Failed to attach policy to the role")
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__, "Failed to attach " + POLICY_NAME + " policy with " + ROLE_NAME + " role: " + err.message)
    return True

def create_role(iam_client, trust_policy):
    """
    This function is to wraps the boto3 iam create_role method with error handling and
    check to verify if the IAM role already exists in the account.
    """
    try:
        role_resp = iam_client.get_role(RoleName=ROLE_NAME)
        print("INFO: IAM Role " + role_resp['Role']['Arn'] + " exists on the account")
    except ClientError as err:
        if err.response['Error']['Code'] != 'NoSuchEntity':
            print("ERROR: Failed to get details of " + ROLE_NAME + " role")
            print("ERROR: " + err.message)
            raise_exception(err.__class__.__name__, "Failed to get role details: " + err.message)
        print("INFO: IAM role " + ROLE_NAME + " is not available in the account, proceeding to provision the IAM role")

        try:
            role_resp = iam_client.create_role(
                RoleName=ROLE_NAME,
                AssumeRolePolicyDocument=json.dumps(trust_policy)
            )
            print("INFO: IAM Role " + role_resp['Role']['Arn'] + " is provisioned on the account")
        except ClientError as err:
            print("ERROR: Failed to create " + ROLE_NAME + " role")
            print("ERROR: " + err.message)
            raise_exception(err.__class__.__name__, "Failed to create " + ROLE_NAME + " role: " + err.message)
    return True

def get_policy_status(iam_client, iam_resource, policy_arn):
    '''function to check the policy status
       retruns the policy status, number of policy versions, and default version'''
    try:
        policy = iam_client.get_policy(PolicyArn=policy_arn)
        print("INFO: Policy " + POLICY_NAME + " already exists in the account ")
        default_version = policy['Policy']['DefaultVersionId']
    except ClientError as err:
        if err.response['Error']['Code'] == 'NoSuchEntity':
            print("INFO: " + policy_arn + " does not exist in the account ")
        else:
            print("ERROR: Failed to get " + POLICY_NAME + " policy details")
            print("ERROR: " + err.message)
            raise_exception(err.__class__.__name__, "Failed to get " + POLICY_NAME + " policy details: " + err.message)
        return False, False, None, None

    try:
        policy_resource = iam_resource.Policy(policy_arn)
        policy_versions = [ver.version_id for ver in policy_resource.versions.all()]
    except ClientError as err:
        print("ERROR: Failed to get " + POLICY_NAME + " policy versions")
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__, "Failed to get " + POLICY_NAME + " policy versions: " + err.message)

    try:
        response = iam_client.list_entities_for_policy(PolicyArn=policy_arn, EntityFilter='Role')
    except ClientError as err:
        print("ERROR: Failed to list " + POLICY_NAME + " policy relationship")
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__, "Failed to list " + POLICY_NAME + " policy relationship: " + err.message)

    try:
        next(role for role in response['PolicyRoles'] if role['RoleName'] == ROLE_NAME)
        print("INFO: Policy " + POLICY_NAME + " is associated with " + ROLE_NAME + " role")
    except StopIteration:
        print("INFO: Policy " + POLICY_NAME + " is not associated with " + ROLE_NAME + " role")
        return True, False, policy_versions, default_version
    return True, True, policy_versions, default_version

def result_json(status, message, role_data=None):
    '''helper function to construct and return the output in json format'''
    result = {}
    result['status'] = status
    result['message'] = message
    if role_data is not None:
        result['data'] = {}
        result['data']['role_arn'] = role_data['role_arn']
        result['data']['policy_arn'] = role_data['policy_arn']
        result['data']['policy_versions'] = role_data['policy_versions']
        result['data']['default_policy_version'] = role_data['default_policy_version']
    return result

def lambda_handler(event, context):
    '''
    lambda_handler receives account_id, access_key, secret_key, and session_token as event data
    Checks for compliance IAM role and the assciated IAM policy on the cross account specified in AccountID
    If compliance IAM role or the associated IAM policy is missing this function creates them
    and returns the outcome of the compliance role provisioning as json object
    '''
    account_id = event.get('account_id')
    access_key = event.get('access_key')
    secret_key = event.get('secret_key')
    session_token = event.get('session_token')

    validate_credentials(account_id, access_key, secret_key, session_token)

    rolearn = 'arn:aws:iam::' + event['account_id'] + ':role/' + ROLE_NAME
    policyarn = 'arn:aws:iam::' + event['account_id'] + ':policy/' + POLICY_NAME

    try:
        policydoc = json.load(open("./policies/" + ROLE_NAME + "/"+ POLICY_NAME + '.json'))
        trustpolicydoc = json.load(open("./policies/" + ROLE_NAME + "/"+ POLICY_NAME + '-trust.json'))
    except Exception as err:
        print("ERROR: Failed to load policy json document")
        raise_exception(err.__class__.__name__, "Failed to load policy json document")

    iam_client = boto3.client(
        'iam',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token
    )

    iam_resource = boto3.resource(
        'iam',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token
    )

    data = {}
    data['role_arn'] = rolearn
    data['policy_arn'] = policyarn

    policy_exists, role_attached, policy_vers, default_ver = get_policy_status(iam_client, iam_resource, policyarn)
    num_vers = len(policy_vers) if policy_vers else 0

    if policy_exists and role_attached:
        policy_vers, default_ver = create_policy_version(iam_client, policy_vers, policyarn, policydoc)

    if policy_exists and not role_attached:
        policy_vers, default_ver = create_policy_version(iam_client, policy_vers, policyarn, policydoc)
        create_role(iam_client, trustpolicydoc)
        attach_role_policy(iam_client, policyarn)


    if not policy_exists:
        policy_vers, default_ver = create_policy(iam_client, policydoc)
        create_role(iam_client, trustpolicydoc)
        attach_role_policy(iam_client, policyarn)

    data['policy_versions'] = policy_vers
    data['default_policy_version'] = default_ver
    return result_json(True, "Successfully provisioned " + ROLE_NAME + " role and attached policy " + POLICY_NAME, data)
