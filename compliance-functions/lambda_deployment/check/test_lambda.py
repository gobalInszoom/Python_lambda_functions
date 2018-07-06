#!/usr/bin/python2.7
"""
Description: This function checks if the defined tesco config rules are present
"""
from __future__ import print_function

import json
import boto3
from botocore.exceptions import ClientError

class LambdaException(Exception):
    """
    Description:this class is used for capturing all the exceptions
    """
    pass

def assume_role(account_id):
    """
    Description: This function receives account_id as the query parameter and the assumes
    a role from the cross account to run its lambda for evaluating the user compliance.
    During the process it generates the temproary credentials to access the cross account
    resources. It returns config object of the cross ccount
    """
    try:
        print ("INFO: Assuming the role of cross Account for testing")
        response = boto3.client('sts').assume_role(
            DurationSeconds=900,
            RoleArn="arn:aws:iam::"+account_id+":role/tesco-splunk-read",
            RoleSessionName='iam_user_compliance'
        )
        print ("INFO: Getting Temproary Credentials to Access the Cross Account Resources")
        config = boto3.client(
            'config',
            aws_access_key_id=response['Credentials']['AccessKeyId'],
            aws_secret_access_key=response['Credentials']['SecretAccessKey'],
            aws_session_token=response['Credentials']['SessionToken'],
        )
        return config
    except Exception as exc:
        exception_type = exc.__class__.__name__
        exception_message = exc.message
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)

def get_cis_rules(cis_rule_file):
    """
    Description: This function reads file tesco-config-rules.txt which is packaged
    together with this lambda function and returns the list of tesco standard config
    rules
    """
    try:
        rule = open(cis_rule_file, 'r')
        cis_rules = rule.read().strip()
        tesco_config_rules = cis_rules.split(',')
        return tesco_config_rules
    except Exception as exc:
        exception_type = exc.__class__.__name__
        exception_message = "Input file not found"
        api_exception_obj = {
            "isError": True,
            "type": exception_type,
            "message": exception_message
        }
        api_exception_json = json.dumps(api_exception_obj)
        raise LambdaException(api_exception_json)

def evaluate_config_rule(tesco_config_rules, config):
    #pylint: disable=unused-argument
    """
    Description: This function gets  config rules present in the target account and
    compares it against tesco standard rules. It considers account is compliant only
    if all the tesco standard cis rules present else it considers as non compliant.
    It returns json object of compliance status,message and status of each config rule
    """
    response = {}
    response_data = {}
    is_compliant = True
    for rule in tesco_config_rules:
        try:
            if config.describe_config_rules(ConfigRuleNames=[rule]):
                response_data.update({rule:True})
        except ClientError:
            print("WARN: "+rule+" rule doesnt exist")
            is_compliant = False
            response_data.update({rule: False})
    if is_compliant:
        response.update({
            "status":True,
            "message":"Account is COMPLIANT as all the tesco standard CIS rules are present",
            "data": response_data})
    else:
        response.update({
            "status":False,
            "message":"Account is NONCOMPLIANT as all the tesco standard CIS rules are not present",
            "data":response_data})
    return response

#pylint: disable=maybe-no-member
def lambda_handler(event, context):
    # pylint: disable=W0612,W0613
    """
    This lambda_handler is the main function which is called by the api gateway.
    It receives account_id as the query parameter and the assumes a role from the
    cross account to run its lambda for evaluating the user compliance. During the
    process it generates the temproary credentials to access the cross account
    resources. The function returns the list of users as json object to the gateway
    """
    config = assume_role(event['account_id'])
    tesco_cis_rules = get_cis_rules('tesco-config-rules.txt')
    if tesco_cis_rules is not None:
        response = evaluate_config_rule(tesco_cis_rules, config)
    else:
        print("""ERROR: Unable to check tesco standard CIS rules since
                 Reference CIS rules file does not exist.""")
        response = {
            "status":False,
            "message":"Internal server error.Unable to check tesco standard CIS rules",
            "data": None}
    return response
