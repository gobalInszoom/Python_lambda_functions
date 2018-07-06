##!/usr/bin/python2.7
"""
This function creates Tesco standard CIS rules on the target account
"""
from __future__ import print_function
import json
import os
import shutil
from zipfile import ZipFile
import threading
from collections import OrderedDict
import boto3
#import botocore
from botocore.exceptions import ClientError

LAMBDA_ROLE = "aws-config-lambda-rules-executor-eu-west-1"
CONFIG_METADATA_FILE = "config-rule-metadata.json"
ROLLBACK_FLAG = False
EXCEPTION_MSG = ""

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
    """
    function to validate the aws account id and credentials
    supplied  via the lambda event
    """
    if any(arg is None for arg in [account_id, access_key, secret_key]):
        print("ERROR: Invalid Credentials supplied")
        raise_exception("ClientError",
             """Invalid account ID or credentials supplied,please check
              whether the account ID or supplied credentials are valid""")

    if not account_id.isdigit() or len(account_id) != 12:
        print("ERROR: Invalid Account ID supplied")
        raise_exception("ClientError", """Invalid account id supplied, please
         check whether the account ID is valid. It should be 12 digits""")

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
        raise_exception(err.__class__.__name__,
                        "Failed to get caller identity: " + err.message)

    if caller_account_id != account_id:
        print("ERROR: Mismatch of account ID and credentials supplied")
        raise_exception("ClientError",
                        "Invalid account ID or credentials supplied")

def is_prereq_available():
    """Check if the pre-requisites are available on the target account"""
    return True, "Pre-req are present"

def parse_json_data(config_json):
    """
    Reads conifg metadata file
    """
    try:
        file_content = open(config_json)
        config_metadata = json.load(file_content)
        file_content.close()
        print("INFO : Reading config-rule-metadata file")
        return config_metadata

    except Exception as err:
        print("ERROR : There was an error while reading " + config_json)
        print("ERROR: " + err.message)
        raise_exception(err.__class__.__name__,
            "Failed to read " + config_json + " file " + err.message)

def get_clients(event):
    """This returns boto clients for config and lambda resource"""
    client = {}
    client["config"] = boto3.client(
        'config',
        aws_access_key_id=event['access_key'],
        aws_secret_access_key=event['secret_key'],
        aws_session_token=event['session_token']
        )
    client["lambda"] = boto3.client(
        'lambda',
        aws_access_key_id=event['access_key'],
        aws_secret_access_key=event['secret_key'],
        aws_session_token=event['session_token']
        )
    return client

def check_config_rules(config_metadata, config_client):
    """This function returns the list of config rules to be created and
    list of config rules that are already present in the target account"""
    config_rule_exists, config_rule_to_be_applied = [], []
    try:
        target_config_data = config_client.describe_config_rules()
        tesco_standard_rules = list(rule for rule in config_metadata)
        target_account_rules = list(object['ConfigRuleName']
        for object in target_config_data['ConfigRules']
        )
        config_rule_exists = list(
        set(tesco_standard_rules).intersection(target_account_rules)
        )
        config_rule_to_be_applied = list(
            set(tesco_standard_rules) - set(target_account_rules)
        )
        return config_rule_exists, config_rule_to_be_applied

    except Exception as err:
        print("ERROR : There was an error while checking config rules ")
        print("ERROR: " + err.message)
        exception_type = err.__class__.__name__
        exception_message = err.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
            }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)

def provision_config_rule(rule, config_metadata, client, lambda_role_arn):
    """This is the starting point of each cis rule creation thread.
    It creates an object of ConfigRule class for given rule and
    creates lambda function and config rule"""
    rule_obj = ConfigRule(rule, config_metadata)
    if rule_obj.create_lambda(client['lambda'], lambda_role_arn):
        rule_obj.create_config(client['config'])


class ConfigRule():
    """
    This class responsible for lambda function and config rule creation
    """
    lambda_created = []
    cis_applied = []
    failed_rules = []
    def __init__(self, rule, config_metadata):
        self.rule_name = rule
        self.lambda_handler = config_metadata[rule][0]["handler_name"]
        self.run_time = config_metadata[rule][0]["run_time"]
        self.description = config_metadata[rule][0]["description"]
        self.tags = config_metadata[rule][0]["tags"]
        self.package_path = self.lambda_handler + ".zip"
        self.resource_type = config_metadata[rule][0]["resource_type"]
        self.trigger_type = config_metadata[rule][0]["trigger_type"]
        self.input_parameters = config_metadata[rule][0]["input_parameters"]
        self.lambda_arn = None

    def create_deploy_package(self):
        """ Creates zip file for lambda function creation"""
        print('INFO : Creating Deployment package for ' + self.rule_name)
        shutil.copy2('./rules/' + self.lambda_handler + '.py', './')
        ZipFile(self.package_path, 'w').write(self.lambda_handler + '.py')

    def create_lambda(self, lambda_client, lambda_role_arn):
        """ Creates lambda function """
        global ROLLBACK_FLAG
        global EXCEPTION_MSG
        print("INFO : Creating lambda function " + self.rule_name)
        try:
            self.create_deploy_package()
            response = lambda_client.create_function(
                FunctionName=self.rule_name,
                Runtime=self.run_time,
                Role=lambda_role_arn,
                Handler=self.lambda_handler,
                Code={"ZipFile": open(
                    "{0}.zip".format(self.lambda_handler), 'rb').read(),},
                Description=self.description,
                Tags=self.tags
                )
            print("INFO : " + self.rule_name + " has been created ")
            self.lambda_arn = response['FunctionArn']
            # Updates lambda function policy to allow function to be called
            # by respective config rule
            response = lambda_client.add_permission(
                Action='lambda:InvokeFunction',
                FunctionName=self.rule_name,
                Principal='config.amazonaws.com',
                StatementId='AllowExecutionFromAWSConfig'
            )
            #Add rule name to lambda_created list once it's got created
            ConfigRule.lambda_created.append(self.lambda_arn)
            return True
        except Exception as err:
            #If there is any exception in lambda function creation, it sets
            #the ROLL_BACK flag to true and add rule name to failed_rules list
            print("ERROR : There was an error while creating " + self.rule_name)
            print("ERROR : " + err.message)
            ROLLBACK_FLAG = True
            EXCEPTION_MSG = err.message
            ConfigRule.failed_rules.append(self.rule_name)
            return False
        finally:
            #This removes the internaly created zip files
            os.remove('./' + self.lambda_handler + '.py')
            os.remove('./' + self.lambda_handler + '.zip')

    def create_config(self, config_client):
        """ Creates config rule """
        global EXCEPTION_MSG
        global ROLLBACK_FLAG
        print("INFO : Creating CIS rule " + self.rule_name)
        try:
            rule = {
                'ConfigRuleName':  self.rule_name,
                'Description': self.description,
                'Scope': {
                    'ComplianceResourceTypes': self.resource_type,
                },
                'Source': {
                    'Owner': 'CUSTOM_LAMBDA',
                    'SourceIdentifier': self.lambda_arn,
                    'SourceDetails': [
                        {
                            'EventSource': 'aws.config',
                            'MessageType': self.trigger_type,
                            #'MaximumExecutionFrequency': 'One_Hour'
                        },
                    ]
                },
                'InputParameters':json.dumps(self.input_parameters)
            }
            response = config_client.put_config_rule(ConfigRule=rule)
            #Add rule name to cis_applied list once it's got created
            ConfigRule.cis_applied.append(self.rule_name)
            print("INFO : CIS rule " + self.rule_name + " has been created")

        except Exception as err:
            # If there is any exception in config creation, it sets the
            # ROLL_BACK flag to true and add rule name to failed_rules list
            print("ERROR : Failed to create config rule" + self.rule_name)
            print("ERROR: " + err.message)
            ConfigRule.failed_rules.append(self.rule_name)
            ROLLBACK_FLAG = True
            EXCEPTION_MSG = err.message

def roll_back(config_client, lambda_client):
    """ This function deletes the created lambda functions and config rules """
    global EXCEPTION_MSG
    try:
        for rule in ConfigRule.cis_applied:
            response = config_client.delete_config_rule(ConfigRuleName=rule)
            print("INFO : Deleted config rule " + rule)

        for func in ConfigRule.lambda_created:
            response = lambda_client.delete_function(FunctionName=func)
            print("INFO : Deleted lambda function " + func)
        return True
    except Exception as err:
        print("ERROR : There was an error while deleting config rules ")
        print("ERROR: " + err.message)
        EXCEPTION_MSG = err.message
        return False

def response_data(existing_rules, created_rules,
             failed_rules, rollback_msg="", custom_msg=""):
    """ This returns data response"""
    #data = OrderedDict()
    # data = {
    #     "created_rules_total":len(created_rules),
    #     "existing_rules_total":len(existing_rules),
    #     "failed_rules_total":len(failed_rules),
    #     "created_rules_name":created_rules,
    #     "existing_rules_name":existing_rules,
    #     "failed_rules_name":failed_rules,
    #     "rollback_message":rollback_msg,
    #     "custom_message":custom_msg
    # }
    data = OrderedDict([
        ("created_rules_total",len(created_rules)),
        ("existing_rules_total",len(existing_rules)),
        ("failed_rules_total",len(failed_rules)),
        ("created_rules_name",created_rules),
        ("existing_rules_name",existing_rules),
        ("failed_rules_name",failed_rules),
        ("rollback_message",rollback_msg),
        ("custom_message",custom_msg)
    ])
    return data

def response_json(status, message, data):
    """ This return response as lambda function output"""
    return json.dumps({
        "status": status,
        "message": message,
        "data": data
        })

def lambda_handler(event, context):
    """
    This function takes the account
    """
    #Validate account_id
    account_id = event.get('account_id')
    access_key = event.get('access_key')
    secret_key = event.get('secret_key')
    session_token = event.get('session_token')
    validate_credentials(account_id, access_key, secret_key, session_token)
    print("INFO : Given credentials are valid")

    #Check if the pre-requisites are available on the target account
    prereq_status, message = is_prereq_available()
    if not prereq_status:
        return response_json(prereq_status, message, {})
    print("INFO : Pre-requisites check is completed")

    #Reads conifg metadata file
    config_metadata = parse_json_data(CONFIG_METADATA_FILE)
    client = get_clients(event)
    lambda_role_arn = 'arn:aws:iam::' + account_id + ':role/' + LAMBDA_ROLE

    #Identifies the list of config rules to be created on target account
    config_rule_exists, config_rule_to_be_created = check_config_rules(
        config_metadata, client['config']
        )
    if not config_rule_to_be_created:
        return response_json(
            False,
            "Configuration rules are already present, no action taken",
            response_data(config_rule_exists, [], [], "no rollback needed",
                "config rules are already present. No action taken")
            )

    #Creates the config rules in config_rule_to_be_created list parallelly
    # using threads
    thread_pool = []
    for rule in config_rule_to_be_created:
        thread = threading.Thread(
            name=rule,
            target=provision_config_rule,
            args=(rule, config_metadata, client, lambda_role_arn,)
            )
        thread_pool.append(thread)
        thread.start()
    #waits for thread to complete
    map(threading.Thread.join, thread_pool)

    #Perform rollback if rollback flag is set
    if ROLLBACK_FLAG:
        print(" ---------------- INFO : Rolling back ----------------------")
        #sets custom_msg based on the rollback status
        if roll_back(client['config'], client['lambda']):
            custom_msg = "Successfully rolled back created CIS rules"
            print("INFO : " + custom_msg)
        else:
            custom_msg = """Rollback is failed. Please delete the above rules,
            lambda functions manually"""
            print("ERROR : " + custom_msg)
        return response_json(
            False,
            "Configuration rules creation is failed",
            response_data(config_rule_exists, ConfigRule.cis_applied,
                ConfigRule.failed_rules, custom_msg, EXCEPTION_MSG)
            )
    else:
        print("INFO : Successfully created CIS rules")
        return response_json(
            True,
            "Configuration rules are created successfully",
            response_data(config_rule_exists, ConfigRule.cis_applied, [],
                "no rollback needed", "config rules are created successfully")
            )
