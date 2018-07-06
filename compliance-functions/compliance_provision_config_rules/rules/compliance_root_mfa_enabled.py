#!/usr/bin/python2.7
"""
Ensure MFA is enabled for root account
Description: This function maps to IAM 1.13 of AWS CIS Foundation Benchmark
Access account summary to check details of root mfa

Trigger Type: Periodic
Required Parameter: None
"""

from __future__ import print_function
import json
import boto3
from botocore.exceptions import ClientError

CONFIG = boto3.client("config")
IAM = boto3.client("iam")

def evaluate_compliance():
    """
    The root account is hierarchically above any IAM Users,
    boto3 iam list_mfa_devices api does not list the root account MFA device
    So check if MFA is enabled at account level
    """
    try:
        mfa_enabled = IAM.get_account_summary()['SummaryMap']['AccountMFAEnabled']
    except ClientError as err:
        print("Error getting account summary: " + err.message)
        return "NON_COMPLIANT"

    if mfa_enabled == 1:
        return "COMPLIANT"
    return "NON_COMPLIANT"



def lambda_handler(event, context):
    """
    Lambda handler is the entry point to function that gets invoked by the invoking event
    """
    invoking_event = json.loads(event["invokingEvent"])
    account_id = event['accountId']
    result_token = "No token found."
    if "resultToken" in event:
        result_token = event["resultToken"]

    CONFIG.put_evaluations(
        Evaluations=[
            {
                "ComplianceResourceType": 'AWS::::Account',
                "ComplianceResourceId": account_id,
                "ComplianceType": evaluate_compliance(),
                "Annotation":"Ensure MFA is enabled for root account",
                "OrderingTimestamp": invoking_event['notificationCreationTime']
            },
        ],
        ResultToken=result_token
    )
