#!/usr/bin/python2.7
'''
    Purpose: Lambda Function to check whether TescoADFS identity provider exists
    on specified account
'''
from __future__ import print_function
from datetime import datetime
import json
import boto3
from botocore.exceptions import ClientError

class ClientException(Exception):
    '''Exception function to handle ClientException with custom messages'''
    pass

class LambdaException(Exception):
    '''Exception function to handle LambdaException with custom messages'''
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

def result_json(status, message, identity_provider_status, valid_creation_date_status):
    ''' Helper function to construct and return the output in json format '''
    result = {}
    result['data'] = {}
    result['status'] = status
    result['message'] = message
    result['data']['identityprovider'] = identity_provider_status
    result['data']['validcreationdate'] = valid_creation_date_status
    return result

def check_identity_provider(sts_credentials, identity_provider_arn, valid_idp_date):
    # pylint: disable=W0703
    ''' Function to check if the required identity provider exists and creation date is valid '''
    try:
        iam = boto3.resource(
            'iam',
            aws_access_key_id=sts_credentials['AccessKeyId'],
            aws_secret_access_key=sts_credentials['SecretAccessKey'],
            aws_session_token=sts_credentials['SessionToken']
            )
        print("INFO: Created temporary secret key and access id successfully")
    except ClientError as exc:
        raise_exception("ClientError", "Issue with the keys:" + exc.message)

    validcreationdate = False
    identityprovider = False
    try:
        saml_provider = iam.SamlProvider(identity_provider_arn)
        if saml_provider.create_date.replace(tzinfo=None) >= valid_idp_date:
            validcreationdate = True
            identityprovider = True
            return validcreationdate, identityprovider
        identityprovider = True
        return validcreationdate, identityprovider
    except ClientError as exc:
        return False, False

def check_assume_role(sts_client, duration, role_arn, session_name):
    ''' Function to assume the compliance role'''
    sts_response = {}
    try:
        sts_response = sts_client.assume_role(
            DurationSeconds=duration,
            RoleArn=role_arn,
            RoleSessionName=session_name
            )
        if sts_response['ResponseMetadata']['HTTPStatusCode'] == 200:
            print("INFO: Sucessfully assumed compliance role...")
            return sts_response
    except ClientError as exc:
        raise_exception(
            exc.__class__.__name__,
            "Failed to check TescoADFS identity provider:" + exc.message
            )

def check_account(account_id):
    ''' Function to check if the account number is not empty and is digit '''
    if account_id is None:
        raise_exception(
            "ClientError",
            "Failed to get account Number and it's empty: " +  exc.message
            )
    elif not account_id.isdigit():
        raise_exception(
            "ClientError",
            "Failed invalid account number:" + exc.message
            )

def lambda_handler(event, context):
    # pylint: disable=W0613
    '''
    lamda_handler method is the main function which will be called by the API gateway.
    It receives an account_id as event data, and assumes tesco-app-compliance role on the
    account_id and checks whether identity provider TescoADFS is present.
    If it is present, it returns true. If not, it returns false.
    '''
    valid_idp_date = event.get("valid_idp_date", datetime.strptime("04/28/17", "%m/%d/%y"))

    # Get specified account id
    account_id = event['account_id']
    check_account(account_id)

    # Construct the expected IDP ARN
    rolearn = 'arn:aws:iam::' + account_id + ':role/tesco-app-compliance'
    identityproviderarn = 'arn:aws:iam::' + account_id + ':saml-provider/TescoADFS'
    stsclient = boto3.client('sts')

    # Assume role to specified account
    print("INFO: Attempting to assume the role: " + rolearn)

    stsresponse = check_assume_role(
        stsclient,
        900,
        rolearn,
        'compliance_session'
        )

    # Check identity proivder and valid creation date
    validcreationdate = False
    identityprovider = False
    print("INFO: Getting identity provider details of account: " + account_id)
    validcreationdate, identityprovider = check_identity_provider(
        stsresponse['Credentials'],
        identityproviderarn,
        valid_idp_date
    )

    if not identityprovider:
        print("ERROR: Identity provider TescoADFS not found")
        return result_json(
            False,
            "TescoADFS Identity provider  not found, please use \
compliance_provision_identity_provider self service script to \
provision this resource on your account",
            False,
            False
        )

    if not validcreationdate:
        print("ERROR: Identity provider TescoADFS found, but cretion date invalid")
        return result_json(
            False,
            "TescoADFS Identity provider found, but invalid federatedmetadata creation date.\
Please use compliance_provision_identity_provider self service script to provision this updated\
federatedmetadata document for indentity provider on your account",
            True,
            False
        )

    return result_json(
        True,
        "This account has valid TescoADFS identity provider",
        True,
        True
    )
