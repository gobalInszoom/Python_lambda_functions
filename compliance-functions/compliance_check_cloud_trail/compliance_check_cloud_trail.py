from __future__ import print_function
import json
import boto3

class ClientException(Exception):
    pass

class LambdaException(Exception):
    pass


class TrailValidation(object):
    ''' This class is to initialize account number '''

    def __init__(self, account_id=None):
        ''' This is the constructor method of class '''
        self.account_id = account_id
        print("INFO:Starting the validation for account %s"%self.account_id)

class AssumeRoleLogin(TrailValidation):
    ''' This class is responsible for assume role'''
    def __init__(self, account_id):
        TrailValidation.__init__(self, account_id)
        self.aws_access_key_id = None
        self.aws_secret_access_key = None
        self.aws_session_token = None
        self.role_arn = None
        self.credentials = None
        self.assume_role_object = None
        self.role_name = "tesco-app-compliance"
  
    def check_account(self):
        if not self.account_id.isdigit():
            exception_type = "ClientError"
            exception_message = "please enter valid account number"
            api_exception_obj = {}
            api_exception_obj = {"isError": True,
                                 "type": exception_type,
                                 "message": exception_message}
            # Create a JSON string
            api_exception_json = json.dumps(api_exception_obj)
            raise LambdaException(api_exception_json)

    def get_role_arn(self):
        ''' This method is constructing role arn based on account no'''
        self.check_account()
        self.role_arn = "arn:aws:iam::" + self.account_id + ":role/"+self.role_name
        print("INFO:We are validating with assume role arn %s"%self.role_arn)

    def get_login_details(self):
        ''' This method calls aws api , assumes roles and return temporary cedentials'''
        sts_client = boto3.client('sts')
        self.get_role_arn()
        try:
            self.assume_role_object = sts_client.assume_role(
                RoleArn=self.role_arn,
                RoleSessionName="sessiontest"
            )
        except Exception as e:
            exception_type = e.__class__.__name__
            exception_message = e.message
            api_exception_obj = {}
            api_exception_obj = {"isError": True,
                                 "type": exception_type,
                                 "message": exception_message}
            # Create a JSON string
            api_exception_json = json.dumps(api_exception_obj)
            raise LambdaException(api_exception_json)
        self.credentials = self.assume_role_object['Credentials']
        print("INFO:Assume role is successful")

    def get_session_details(self):
        ''' This method intialises the session details '''
        self.get_login_details()
        self.aws_access_key_id = self.credentials['AccessKeyId']
        self.aws_secret_access_key = self.credentials['SecretAccessKey']
        self.aws_session_token = self.credentials['SessionToken']
        print("INFO:Created temporary secreate key and access id successfully")

class ValidateTrail(AssumeRoleLogin):
    '''This class is reponsible for validation of configuration of cloud trail '''
    def __init__(self, account_id, prod_trail_bucket_name):
        AssumeRoleLogin.__init__(self, account_id)
        self.is_trail_enabled_multi_region = False
        self.is_prod_bucket_configured = False
        self.prod_trail_bucket_name = prod_trail_bucket_name
        self.get_session_details()
        self.response = {}
        self.data = {}
        self.session_data = None
        self.cloud_trail_region = 'eu-west-1'

    def cloud_trail_enabled(self):
        '''This method verifies that trail is active and enabled in all region ,
           as well correct prod bucket configured'''
        ct_client = boto3.client('cloudtrail', region_name=self.cloud_trail_region,
                                 aws_access_key_id=self.aws_access_key_id,
                                 aws_secret_access_key=self.aws_secret_access_key,
                                 aws_session_token=self.aws_session_token)
        ct_response = ct_client.describe_trails()
        trails = ct_response["trailList"]
        for trail in trails:
            self.is_trail_enabled_multi_region = trail["IsMultiRegionTrail"]
            print("Status of trail for all region is %s"%self.is_trail_enabled_multi_region)
            if self.prod_trail_bucket_name == trail["S3BucketName"]:
                self.is_prod_bucket_configured = True
                print("INFO:It is configured with production bucket properly")
                break
            else:
                pass

    def get_cloudtrail_compliance(self):
        '''This method composes the response and send it back '''
        self.cloud_trail_enabled()
        if self.is_trail_enabled_multi_region and self.is_prod_bucket_configured:
            self.response["status"] = True
            self.response["message"] = "This account is compliant with Cloud Trail"
            self.data["cloudtrail_enabled_all_region"] = self.is_trail_enabled_multi_region
            self.data["logs_in_central_s3"] = self.is_prod_bucket_configured
            self.response["data"] = self.data
        else:
            self.response["status"] = False
            self.response["message"] = "This account is not compliant with Cloud Trail."
            self.data["cloudtrail_enabled_all_region"] = self.is_trail_enabled_multi_region
            self.data["logs_in_central_s3"] = self.is_prod_bucket_configured
            self.response["data"] = self.data
        return self.response

def lambda_handler(event, context):
    '''This the entry method for lambda it return the root account details like mfa enabled
	or not access key present or not. It recieves account id as input parameter'''
    #Create AWS clients for iam
    account_id = event['account_id']
    validatetrail_data = ValidateTrail(account_id, 'tesco-cloudtrail-bucket-prod')
    response = validatetrail_data.get_cloudtrail_compliance()
    return response
