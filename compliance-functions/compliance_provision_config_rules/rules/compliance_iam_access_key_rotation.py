#!/usr/bin/python2.7
"""
    Ensure access keys are rotated every 90 days or less
    Description: This function maps to IAM 1.4 of AWS CIS Foundation Benchmark

    Trigger Type: Change Triggered
    Scope of Changes: IAM:User
    Required Parameter: MaximumAccessKeyAge
"""

from __future__ import print_function
import time
import json
from datetime import datetime
import boto3
from botocore.exceptions import ClientError

IAM = boto3.client("iam")
CONFIG = boto3.client("config")
FMT = '%Y-%m-%dT%H:%M:%S+00:00'
NOW = time.strftime(FMT, time.gmtime(time.time()))

APPLICABLE_RESOURCES = ["AWS::IAM::User"]


def normalize_parameters(rule_parameters):
    """
    Normalize rule parameters to be used with python
    """
    for key, value in rule_parameters.iteritems():
        if value.isdigit():
            rule_parameters[key] = int(value)
        rule_parameters[key[0].upper() + key[1:]] = rule_parameters.pop(key)
    return rule_parameters


def evaluate_compliance(configuration_item, rule_parameters):
    """
    Validate the accesskey age for each accesskey associated with the given user
    """
    if configuration_item["resourceType"] not in APPLICABLE_RESOURCES:
        return {
            "compliance_type": "NOT_APPLICABLE",
            "annotation": "Rule doesn't apply to resources of type "
                          + configuration_item["resourceType"]
        }

    try:
        keydata = IAM.list_access_keys(UserName=configuration_item["resourceName"])
    except ClientError as err:
        print("Error: Failed to list user access keys")
        print("Error: " + err.message)
        return {
            "compliance_type": "INSUFFICIENT_DATA",
            "annotation": "Failed to list user access keys"
        }
    if keydata['AccessKeyMetadata']:
        for data in keydata['AccessKeyMetadata']:
            key_age = datetime.strptime(NOW, FMT) - data['CreateDate'].replace(tzinfo=None)
            if key_age.days > rule_parameters['MaximumAccessKeyAge']:
                return {
                    "compliance_type": "NON_COMPLIANT",
                    "annotation": "User is not compliant with access key rotation policy"
                }
    return {
        "compliance_type": "COMPLIANT",
        "annotation": "User is compliant with access key rotation policy"
    }


def lambda_handler(event, context):
    """
    Lambda handler gets invoked on the trigger
    """
    invoking_event = json.loads(event["invokingEvent"])
    configuration_item = invoking_event["configurationItem"]
    rule_parameters = normalize_parameters(json.loads(event["ruleParameters"]))

    result_token = "No token found."
    if "resultToken" in event:
        result_token = event["resultToken"]

    evaluation = evaluate_compliance(configuration_item, rule_parameters)

    CONFIG.put_evaluations(
        Evaluations=[
            {
                "ComplianceResourceType":
                    configuration_item["resourceType"],
                "ComplianceResourceId":
                    configuration_item["resourceId"],
                "ComplianceType":
                    evaluation["compliance_type"],
                "Annotation":
                    evaluation["annotation"],
                "OrderingTimestamp":
                    configuration_item["configurationItemCaptureTime"]
            },
        ],
        ResultToken=result_token
    )
