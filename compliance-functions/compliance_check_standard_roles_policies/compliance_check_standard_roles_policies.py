'''
    Created Date: 23-05-2017
    Purpose: Lambda function which checks for the default roles and policy
'''
from __future__ import print_function
import json
import hashlib
import threading
import Queue as queue
from collections import OrderedDict
import boto3
import botocore

response_data = {}
#response_data['status'] = True

class LambdaError(Exception):
    """docstring for ClassName"""
    pass

def ordered(obj):
    '''
    Function to sort json object
    '''
    if isinstance(obj, dict):
        return sorted((k, ordered(v)) for k, v in obj.items())
    elif isinstance(obj, list):
        return sorted(ordered(x) for x in obj)
    else:
        return obj

def evaluate_content_modification(attached_policy, iam, role, mod_q):
    '''
    evaluate if the content of the policy is being modified
    '''
    pol_name = attached_policy['PolicyName']
    non_compliant_policy = {}
    with open(role+'/'+attached_policy['PolicyName']+'.json') as data_file:
        policy_file = json.load(data_file)
    policy_actual = iam.get_policy(PolicyArn=attached_policy['PolicyArn'])
    policyversion = iam.get_policy_version(PolicyArn=attached_policy['PolicyArn'], VersionId=
                                           policy_actual['Policy']['DefaultVersionId'])
    target_policy = hashlib.md5(json.dumps(ordered(policyversion['PolicyVersion']
                                                   ['Document']['Statement'])).
                                encode('utf')).hexdigest()
    reference_policy = hashlib.md5(json.dumps(ordered(policy_file['Statement']))
                                   .encode('utf')).hexdigest()
    if target_policy != reference_policy:
        non_compliant_policy['name'] = pol_name
        mod_q.put(non_compliant_policy)
        response_data['status'] = False

def evaluate_policy(role, policies, iam, attached_list, role_q):
    '''
    evaluate_policy will check for the total number of policies attached to the
    role. It checks if any additional policies is been attached to the role,
    checks if any unwanted policies is been attached to the role and also checks
    if the role is been modified.
        input args: (role, policies, iam)
        return: policy_result
            policy_result = list of compliant, non-compliant and policies to be
                attached to the role
    '''
    custom_policies = []
    policy_tobe_attached = []
    policy_names = []
    role_result = OrderedDict()
    role_result['role'] = role
    role_result['present'] = True
    non_compliant_policies = []
    threads = []
    mod_q = queue.Queue()
    for attached_policy in attached_list:
        policy_names.append(attached_policy['PolicyName'])
        policy_name = attached_policy['PolicyName'].replace("-", "_")
        if attached_policy['PolicyName'] in policies:
            print ("INFO: "+policy_name+" is attached to "+role+" role")
            threads.append(threading.Thread(target=evaluate_content_modification,
                                            args=(attached_policy, iam, role, mod_q)))
            threads[-1].start()
        else:
            print ("ERROR: "+policy_name+" should not be attached to "+role+" role")
            custom_policy = {}
            custom_policy['name'] = policy_name
            custom_policies.append(custom_policy)
            response_data['status'] = False
    for policy in policies:
        if not policy in policy_names:
            missing_policy = {}
            print ("ERROR: "+policy+" policy is not been attached to "+role+" role")
            missing_policy['name'] = policy
            policy_tobe_attached.append(missing_policy)
    for single_thread in threads:
        single_thread.join()
    while not mod_q.empty():
        non_compliant_policies.append(mod_q.get())
    role_result['custom_policies'] = custom_policies
    role_result['non_compliant_policies'] = non_compliant_policies
    role_result['missing_policies'] = policy_tobe_attached
    role_q.put(role_result)

def evaluate_role(input_dictionary, iam):
    '''
    evaluate_role is the function which checks if the predefined role is present
    in the account. If present it calls evaluate_policy to check for the policy.
        input_args: (input_dictionary, session, iam)
            input_dictionary: has a list of the roles and policies that needs
                to be evaluated.
        return: evaluation_result
            evaluation_result: is a dictionay and contains the evaluation of the
                roles and policy
    '''
    evaluation_result = []
    threads = []
    role_q = queue.Queue()
    for role, policies in input_dictionary.items():
        role_result = {}
        try:
            attached_list = iam.list_attached_role_policies(RoleName=role)['AttachedPolicies']
            print ("INFO: "+role+" role exists in the account")
            threads.append(threading.Thread(target=evaluate_policy,
                                            args=(role, policies, iam, attached_list, role_q)))
            threads[-1].start()
        except botocore.exceptions.ClientError as err:
            if err.__class__.__name__.upper() == "NoSuchEntityException".upper():
                rol_res = {}
                role_result['role'] = False
                response_data['status'] = False
                rol_res[role.replace("-", "_")] = role_result
                print ('ERROR: Could not find the tesco-app-admin role in the account')
                print (err.message)
                evaluation_result.append(rol_res)
            else:
                response = {}
                response['isError'] = True
                response['type'] = err.__class__.__name__
                response['message'] = err.message
                raise LambdaError(json.dumps(response))
    for single_thread in threads:
        single_thread.join()
    while not role_q.empty():
        evaluation_result.append(role_q.get())
        # role_result['policy'] = role_q.get()
    return evaluation_result

def evaluate_compliance(iam):
    '''
    evaluate_compliance function evaluates whether the defined role and policies
    are present. If any extra policies are been added to the role or if the content
    of the policy is been modified, all these things will be evaluated
    '''
    input_dictionary = {}
    input_dictionary['tesco-app-admin'] = ['tesco-full-access', 'tesco-cloud-trail-deny-disable']
    input_dictionary['tesco-app-developer'] = ['tesco-full-route53-access',
                                               'tesco-read-iam', 'tesco-read-trusted-advisor',
                                               'tesco-full-lambda-access', 'tesco-read-cloud-trail',
                                               'tesco-full-ec2-access', 'tesco-read-portal',
                                               'tesco-full-s3-access']
    input_dictionary['tesco-app-productowner'] = ['tesco-read-trusted-advisor',
                                                  'tesco-read-cloud-trail',
                                                  'tesco-full-iam-access', 'tesco-read-portal']
    input_dictionary['tesco-app-tester'] = ['tesco-read-ec2', 'tesco-read-route53',
                                            'tesco-read-s3']
    return evaluate_role(input_dictionary, iam)

def raiseError(err):
    '''
     Function raises the error
    '''
    response = OrderedDict()
    response['isError'] = True
    if err.__class__.__name__.upper() != "ClientError".upper():
        response['type'] = "ClientError"
        response['message'] = "Class: "+err.__class__.__name__+", "+err.message
    else:
        response['type'] = err.__class__.__name__
        response['message'] = err.message
    return response

def lambda_handler(event, context):
    '''
    lambda_handler is the main function which is called by the api gateway.
    It receives account_id as the query parameter and the assumes a role from the
    cross account to run its lambda for evaluating the user compliance. During the
    process it generates the temproary credentials to access the cross account
    resources. The function returns the list of users as json object to the gateway.
    '''
    print ("INFO: Assuming the role of cross Account")
    response_data.clear()
    print (response_data)
    try:
        role_arn = 'arn:aws:iam::'+str(event['account_id'])+':role/tesco-app-compliance'
        response = boto3.client('sts').assume_role(
            DurationSeconds=900,
            RoleArn=role_arn,
            RoleSessionName='iam_user_compliance'
        )
    except botocore.exceptions.ClientError as err:
        raise LambdaError(json.dumps(raiseError(err)))
    except Exception as err:
        raise LambdaError(json.dumps(raiseError(err)))
    print ("INFO: Getting Temproary Credentials to Access the Cross Account Resources")
    try:
        iam = boto3.client(
            'iam',
            aws_access_key_id=response['Credentials']['AccessKeyId'],
            aws_secret_access_key=response['Credentials']['SecretAccessKey'],
            aws_session_token=response['Credentials']['SessionToken'],
        )
    except botocore.exceptions.ClientError as err:
        raise LambdaError(json.dumps(raiseError(err)))
    except Exception as err:
        raise LambdaError(json.dumps(raiseError(err)))
    response_data['data'] = evaluate_compliance(iam)
    if 'status' in response_data.keys():
        response_data['message'] = "Account is non-compliant with the standard roles and policies"
    else:
        response_data['status'] = True
        response_data['message'] = "Account is compliant with the standard roles and policies"
    return response_data
