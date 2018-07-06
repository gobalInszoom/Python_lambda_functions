#!/usr/bin/python3.6
# pylint: disable=E1101
'''
    Purpose: Lambda Function to check whether TescoADFS identity provider exists
    on specified account
'''
from __future__ import print_function
import os
from datetime import datetime
import json
import boto3
from botocore.exceptions import ClientError

# Read config variables from environment, fall back to defaults
VALID_IDP_DATE = os.environ.get("VALID_IDP_DATE", datetime.strptime("04/28/17", "%m/%d/%y"))
FILE_NAME = os.environ.get("FILE_NAME", 'FederationMetadata.xml')

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

def validate_credentials(account_id, access_key, secret_key, session_token):
    '''function to validate the aws account id and credentials supplied  via the lambda event'''
    if any(arg is None for arg in [account_id, access_key, secret_key]):
        print("ERROR: Invalid account or credentials supplied")
        raise_exception(
            "ClientError",
            "Invalid account ID or credentials supplied, \
please check whether the account ID or supplied credentials are valid."
        )

    if not account_id.isdigit() or len(account_id) != 12:
        print("ERROR: Invalid Account ID supplied")
        raise_exception(
            "ClientError",
            "Invalid account id supplied, please check whether the account ID is valid.\
It should be 12 digits."
        )

    sts_client = boto3.client(
        'sts',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token
    )

    try:
        caller_account_id = sts_client.get_caller_identity()['Account']
        print("INFO: Caller Account ID: " + caller_account_id)
    except ClientError as exc:
        print("ERROR: Failed to get caller identity")
        print("ERROR: " + exc.message)
        raise_exception(exc.__class__.__name__, "Failed to get caller identity: " + exc.message)

    if caller_account_id != account_id:
        print("ERROR: Mismatch of account ID and credentials supplied")
        raise_exception("Invalid Account Credentials", "Invalid account ID or credentials supplied,\
 please check whether the correct account ID is selected or supplied credentials are valid.")

def check_identity_provider(access_key, secret_key, session_token, identity_provider_arn):
    # pylint: disable=W0703
    ''' Function to check if the required identity provider exists and creation date is valid '''
    iam_resource = boto3.resource(
        'iam',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token
    )

    validcreationdate = False
    identityprovider = False
    try:
        response = iam_resource.SamlProvider(identity_provider_arn)
        if response.create_date.replace(tzinfo=None) >= VALID_IDP_DATE:
            validcreationdate = True
            identityprovider = True
            return validcreationdate, identityprovider
        identityprovider = True
        return validcreationdate, identityprovider
    except ClientError:
        print("INFO: TescoADFS Identity Provider not found")
        return False, False

def read_xml_document():
    ''' Function to read xml document provider with valid creation '''
    try:
        metadata_file = open(FILE_NAME, 'r')
        metadata_document = metadata_file.read()
        return metadata_document
    except ClientError as exc:
        raise_exception(
            exc.__class__.__name__,
            "Failed to read" + FILE_NAME + "ERROR: " + exc.message
            )

def create_identity_provider(iam_client, metadata_document):
    ''' Function to create identity provider with valid creation '''
    try:
        response = iam_client.create_saml_provider(
            SAMLMetadataDocument=metadata_document,
            Name='TescoADFS'
        )
        return response
    except ClientError as exc:
        raise_exception(exc.__class__.__name__, "Failed to create TescoADFS. ERROR: " + exc.message)

def update_metadata_document(iam_client, metadata_document, identityproviderarn):
    ''' Function to update latest identity provider federated metadata document '''
    try:
        response = iam_client.update_saml_provider(
            SAMLMetadataDocument=metadata_document,
            SAMLProviderArn=identityproviderarn
            )
        return response
    except ClientError as exc:
        raise_exception(
            exc.__class__.__name__,
            "Failed to update TescoADFS metadata document. ERROR: " + exc.message)

def result_json(status, message):
    ''' Helper function to construct and return the output in json format '''
    result = {}
    result['data'] = {}
    result['status'] = status
    result['message'] = message
    return result

def lambda_handler(event, context):
    # pylint: disable=W0613
    '''
    lamda_handler method is the main function which will be called by the API gateway.
    It receives an account_id, access key, and secret key as event data, and checks
    whether identity provider TescoADFS is present. If not, it will create TescoADFS
    identity provider which enables SAML integration. If it is already present, it
    returns false. If its creates new, and its success then it returns true. If creation
    fails, it retusn false.
    '''
    # Get values from input arguments
    account_id = event.get('account_id', None)
    access_key = event.get('access_key', None)
    secret_key = event.get('secret_key', None)
    session_token = event.get('session_token', None)

    # Validate the supplied account id and credentails
    validate_credentials(account_id, access_key, secret_key, session_token)

    # Construct the expected IDP ARN and credentials
    identityproviderarn = 'arn:aws:iam::' + account_id + ':saml-provider/TescoADFS'

    # Check identity proivder and valid creation date
    validcreationdate = False
    identityprovider = False
    print("INFO: Getting identity provider details of account: " + account_id)
    validcreationdate, identityprovider = check_identity_provider(
        access_key,
        secret_key,
        session_token,
        identityproviderarn
    )

    iam_client = boto3.client(
        'iam',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token
        )

    # Read the federatedmetadata document
    metadata_document = read_xml_document()

    if identityprovider and validcreationdate:
        print("INFO: TescoADFS identityprovider with valid date present")
        return result_json(
            False,
            "TescoADFS identity provider was already present,\
with valid federatedmetadata document")

    if not identityprovider:
        print("INFO: Creating TescoADFS identityprovider")
        response = create_identity_provider(iam_client, metadata_document)
        if response['SAMLProviderArn'] == identityproviderarn:
            return result_json(
                True,
                "TescoADFS identity provider was successfully created"
            )
        return result_json(
            False,
            "TescoADFS identity provider was not present and creation failed"
        )

    if not validcreationdate:
        print("INFO: Identity provider TescoADFS found, \
but cretion date invalid. Updating latest federatedmetadata document")
        response = update_metadata_document(iam_client, metadata_document, identityproviderarn)
        if response['SAMLProviderArn'] == identityproviderarn:
            return result_json(
                True,
                "TescoADFS identity provider was already present,\
 but metadata document createion date was invalid.\
 federatedmetadata document was successfully updated"
            )
        return result_json(
            False,
            "TescoADFS identity provider was already present,\
 but federatedmetadata document was not valid and update failed"
        )
