"""
	Class: Lambda Fuction
	Purpose: Api Gateway calls the lambda_function
	Created Date: 14-06-2017
"""
from __future__ import print_function
#import threading
from collections import OrderedDict
import json
import boto3
import policy_class
import roles_class
import botocore

class LambdaError(Exception):
    """docstring for ClassName"""
    pass


def get_sts(event):
    """ Function to get the account number of the called function """
    try:
        print ("INFO: Getting Account Number")
        return boto3.client('sts',
                            aws_access_key_id=event['access_key'],
                            aws_secret_access_key=event['secret_key']).get_caller_identity()['Account']
    except botocore.exceptions.ClientError as err:
        response = OrderedDict()
        response['isError'] = True
        response['type'] = err.__class__.__name__
        response['message'] = err.message

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
    raise LambdaError(api_exception_json)

def validate_credentials(account_id, access_key, secret_key, session_token):
    '''function to validate the aws account id and credentials supplied  via the lambda event'''
    if any(arg is None for arg in [account_id, access_key, secret_key]):
        print("ERROR: Invalid Credentials supplied")
        raise_exception("ClientError", "Invalid account ID or credentials supplied,"+
                        "please check whether the account ID or supplied credentials are valid")

    if not account_id.isdigit() or len(account_id) != 12:
        print("ERROR: Invalid Account ID supplied")
        raise_exception("ClientError", "Invalid account id supplied, please check whether"+
                        "the account ID is valid. It should be 12 digits")
    sts_client = boto3.client(
        'sts',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token
    )

    try:
        caller_account_id = sts_client.get_caller_identity()['Account']
        print("INFO: Caller Account ID: " + caller_account_id)
    except botocore.exceptions.ClientError as err:
        print("ERROR: Failed to get caller identity")
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__, "Failed to get caller identity: " + err.message)

    if caller_account_id != account_id:
        print("ERROR: Mismatch of account ID and credentials supplied")
        raise_exception("ClientError", "Invalid account ID or credentials supplied")


def get_input():
    """ Function to get the input of roles and policies """
    with open('input_roles_policies.json') as data_file:
        input_dictionary = json.load(data_file)
    return input_dictionary

def total_response():
    """ Get the response when all roles and policies are present """
    total_rep = OrderedDict()
    total_rep['status'] = False
    total_rep['message'] = "All roles and policies exist. Hence no action is taken"
    total_rep['data'] = []
    return total_rep

def failed_response(policy_flag, check_roles, check_policies, msg, rollback=True):
    '''
    failed_response function returns the response if the
    creation of the roles and policies has failed.
    '''
    failed_rep = OrderedDict()
    failed_rep['status'] = False
    failed_rep['message'] = "Failed to create the roles and policies"
    data = OrderedDict()
    roles_failed = check_roles.roles_to_create - check_roles.roles_created
    data['total_role_creation_failed'] = len(roles_failed)
    data['total_policies_failed'] = 0
    data['rollback_message'] = "Rollback is successfully"
    data['exception_message'] = msg
    data['failed_roles'] = roles_failed
    data['failed_policies'] = []
    if not rollback:
        data['rollback_message'] = "Rollback is unsuccessfully"
        data['next_step'] = "Please go and delete the below roles and policies manually"
    if policy_flag:
        policy_failed = check_policies.policies_to_create - check_policies.policies_created
        data['total_policies_failed'] = len(policy_failed)
        data['failed_policies'] = policy_failed
    failed_rep['data'] = data
    return failed_rep

def successful_response(check_roles, check_policies):
    '''
    successful_response returns the response if the creation of all roles
    and policies is successful.
    '''
    final_response = OrderedDict()
    final_response['status'] = True
    final_response['message'] = "Successfully created the roles and policies"
    data = OrderedDict()
    data['total_roles_created'] = len(check_roles.roles_created)
    data['total_policies_create'] = len(check_policies.policies_created)
    data['roles_created'] = []
    data['policy_created'] = []
    for role_name in check_roles.roles_created:
        role = {}
        role['name'] = role_name
        data['roles_created'].append(role)
    for policy_name in check_policies.policies_created:
        policy = {}
        policy['name'] = policy_name
        data['policy_created'].append(policy)
    final_response['data'] = data
    return final_response

def lambda_handler(event, context):
    """ lambda_handler called by api gateway """
    validate_credentials(event['account_id'], event['access_key'],
                         event['secret_key'], event['session_token'])
    roles_list = list(get_input().keys())
    iam = boto3.client('iam',
                       aws_access_key_id=event['access_key'],
                       aws_secret_access_key=event['secret_key'],
                       aws_session_token=event['session_token'])
    check_roles = roles_class.RolesClass(iam, event['account_id'])
    check_policies = policy_class.PolicyClass(iam, event['account_id'])
    print("INFO: Checking the standard roles")
    check_roles.check_if_role_exist(roles_list)
    if check_roles.response['isError']:
        print("ERROR: An error occured while checking for standard roles")
        raise LambdaError(json.dumps(check_roles.response))
    print("INFO: Checking the standard policies")
    check_policies.check_if_policy_exist()
    if check_policies.response['isError']:
        print("ERROR: An error occured while checking for standard policies")
        raise LambdaError(json.dumps(check_policies.response))
    if (not check_roles.roles_to_create) and (not check_policies.policies_to_create):
        print("INFO: All roles and policies exist. Hence no action is taken")
        return total_response()
    if check_roles.roles_to_create:
        print("INFO: Creating the roles")
        check_roles.create_roles()
    if check_roles.rollback:
        print("ERROR: An error occured while creating the roles")
        check_roles.delete_roles(get_input(), event['account_id'])
        return failed_response(False, check_roles, check_policies,
                               check_roles.response['message'])
        #raise LambdaError(json.dumps(check_roles.response))
    if check_policies.policies_to_create:
        print("INFO: Creating the policies")
        check_policies.create_policies()
    if check_policies.rollback:
        print("ERROR: An error occured while creating the policies")
        check_policies.delete_policies(event['account_id'])
        check_roles.delete_roles(get_input(), event['account_id'])
        return failed_response(True, check_roles, check_policies,
                               check_policies.response['message'])
        #raise LambdaError(json.dumps(check_policies.response))
    if check_roles.roles_to_create:
        print("INFO: Attaching the policies to required roles")
        check_roles.attach_policies(get_input(), event['account_id'])
    if check_roles.rollback:
        print("ERROR: An error occured while attaching the policies")
        check_policies.delete_policies(event['account_id'])
        check_roles.delete_roles(get_input(), event['account_id'])
        return failed_response(False, check_roles, check_policies, check_roles.response['message'])
    return successful_response(check_roles, check_policies)
