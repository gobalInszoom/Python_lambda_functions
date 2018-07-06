#!/usr/bin/python2.7
'''
    Purpose: Lambda function that checks all ec2 tagged and non tagged
    resources that doesn't match the tesco standard
    on specified account
'''
from __future__ import print_function
import re
import datetime
import json
from threading import Thread
import boto3
import botocore

# pylint: disable=invalid-name,
regiondict = {}
response_tagstd_status = {}
response_dcttagstdbln = {}
response_posblevalue_status = {}
response_dctposblevaluebln = {}
total_result = []
output_response = {}
output_response['status'] = True


class LambdaError(Exception):
    """docstring for ClassName"""
    pass

def check_tesco_std(re_i, dictkeypair):
    """ Check tagkeys are strictly lower case
    Check tagvalues  are strictly lower case
    Check tagvalues refrain from using special characters """

    blnstdcheck = None
    tesco_std_keys = {}
    key_length = 0
    for tagkey, tagvalue in dictkeypair.items():
        if tagkey in ['tesco_environment_class', 'tesco_application', 'tesco_tier',
                      'tesco_version', 'tesco_status', 'tesco_service_id', 'tesco_importance',
                      'tesco_review_date']:
            key_length = key_length + 1
            tesco_std_keys[tagkey] = True
        if tagkey in ['tesco_version', 'tesco_review_date',
                      'tesco_environment', 'tesco_name', 'Name']:
            tesco_std_keys[tagkey] = True
            continue
        if tagkey.islower() and tagvalue.islower() and \
           (not  re.match(r'.*[\(|)\=\;].*', tagvalue)):
            #tag values should refrain from the use of the
            #equals sign (=), pipe (|), and semi-colon (;)
            tesco_std_keys[tagkey] = True
        else:
            blnstdcheck = True
            tesco_std_keys[tagkey] = False
    if key_length != 8:
        blnstdcheck = True
    if  blnstdcheck:
        re_i = re_i + "." + "Non-Compliant"
        response_tagstd_status[re_i] = tesco_std_keys
        output_response['status'] = False
        return False
    else:
        response_dcttagstdbln[re_i] = dictkeypair
        return True

def process_tesco_name(tagvalue):
    """ validate tesco name tag value """
    bln_tesco_name = None
    try:
        if  re.match(r'.*[a-z0-9.-_\s]+.*', tagvalue):
            bln_tesco_name = True
    except Exception as err:
        print("ERROR: Name is not valid" + err)
        bln_tesco_name = False
    return bln_tesco_name

def process_tesco_application(tagvalue):
    """ validate tesco application tag value """
    #bln_tesco_application = None
    # use below code for future purpose
    #tesco_app = []
    #For future use
    # if tagvalue in tesco_app:
    #   bln_tesco_application = True
    # else:
    #     bln_tesco_application = False
    return True

def process_tesco_environment_class(tagvalue):
    """ validate tesco_environment_class tag value """
    bln_tesco_env_class = None
    tesco_env_class = ['prod', 'pre-prod', 'uat', 'training', 'sit', 'dev']
    if tagvalue in tesco_env_class:
        bln_tesco_env_class = True
    else:
        bln_tesco_env_class = False
    return  bln_tesco_env_class

def process_tesco_tier(tagvalue):
    """ validate tesco tier tag value"""
    bln_tescotier = None
    tesco_tier = ['threat', 'web', 'app', 'data', 'network']
    if tagvalue in tesco_tier:
        bln_tescotier = True
    else:
        bln_tescotier = False
    return bln_tescotier

def process_tesco_version(tagvalue):
    """ validate tesco version """
    bln_tesco_version = None
    try:
        pattern = re.compile(r"^(\d+\.)?(\d+\.)?(\*|\d+)$")
        #tag value should match Version . Major.Minor.Patch (Pattern: #.#.#)
        if pattern.match(tagvalue):
            bln_tesco_version = True
        else:
            bln_tesco_version = False
    except Exception as err:
        print("ERROR: version is not valid "+err)
        bln_tesco_version = False
    return bln_tesco_version

def process_tesco_status(tagvalue):
    """ validate tesco status """
    bln_tesco_status = None
    tesco_status = ['active', 'inactive']
    if tagvalue in  tesco_status:
        bln_tesco_status = True
    else:
        bln_tesco_status = False

    return bln_tesco_status

def process_tesco_importance(tagvalue):
    """ validate tesco importance tag value """
    bln_tesco_importance = None
    tesco_importance = ['critical', 'high', 'normal', 'low']
    if tagvalue in tesco_importance:
        bln_tesco_importance = True

    else:
        bln_tesco_importance = False

    return bln_tesco_importance

def process_tesco_review_date(tagvalue):
    """ validate tesco review date"""
    bln_tesco_review_date = None
    try:
        mat = re.match(r'(\d{2})[/](\d{2})[/](\d{4})$', tagvalue)
        #tag value should match date format (DD/MM/YYYY)
        if mat is not None:
            datetime.datetime(*(map(int, mat.groups()[-1::-1])))
            bln_tesco_review_date = True

    except ValueError:
        bln_tesco_review_date = False

    return bln_tesco_review_date

ruleset = {'tesco_application': process_tesco_application,
           'tesco_environment_class': process_tesco_environment_class,
           'tesco_tier': process_tesco_tier,
           'tesco_version': process_tesco_version,
           'tesco_status': process_tesco_status,
           'tesco_importance': process_tesco_importance,
           'tesco_review_date': process_tesco_review_date,
           'tesco_name': process_tesco_name
          }

def check_possible_tagvalues(instance_id, region, taginfo, dictkeypair):
    """ Check all possible tag values accornding to tesco standards"""
    bln_psblevalue_check = None
    tesco_posble_values = {}
    blnoncompliant = None
    s = re.split(r'[.](?![^][]*\])', taginfo)
    # get region, instance id using param taginfo
    found_status_skey = s[2] + "." +  s[1] + "." + "complaint"
    notfound_status_skey = s[2] + "." +  s[1] + "." + "Non-complaint"
    for tagkey, tagvalue in dictkeypair.items():
        if tagkey in  ['tesco_service_id', 'Name', 'tesco_environment']:
            tesco_posble_values[tagkey] = True
            continue
        if tagkey in ruleset:
            bln_psblevalue_check = ruleset[tagkey](tagvalue)
            tesco_posble_values[tagkey] = bln_psblevalue_check
            if not bln_psblevalue_check:
                blnoncompliant = True
    if blnoncompliant:
        response_posblevalue_status[notfound_status_skey] = tesco_posble_values
        output_response['status'] = False
        return False
    else:
        response_dctposblevaluebln[found_status_skey] = dictkeypair
        return True

def process_each_ec2tagkeyvaluepair(regiondict, reg):
    """ Get list of  Instance id specific  to region
    Check tesco mandatory tag exists for all instance
    Check all tags adhere to tesco standard tags"""

    input_dictionary = {}
    compliant = []
    non_compliant = []
    region_result = {}
    region_res = {}
    for instance_details in regiondict['ResourceTagMappingList']:
        instance_keys = {}
        instance_id = str(instance_details['ResourceARN'].split(":")[5].split("/")[1])
        region = str(instance_details['ResourceARN'].split(":")[3])
        key = "ec2.Instance(id="+instance_id+")."+region
        for tags in instance_details['Tags']:
            instance_keys[tags['Key']] = tags['Value']
        input_dictionary[key] = instance_keys
        #print(input_dictionary)
        if check_tesco_std(key, instance_keys):
            if check_possible_tagvalues(instance_id, region, key, instance_keys):
                compliant.append(instance_id)
                continue
        non_compliant.append(instance_id)
    region_result['non_compliant_instances'] = non_compliant
    region_result['compliant_instances'] = compliant
    region_res[reg] = region_result
    return region_res

def list_ec2instance_per_region(region, response):
    """ Get list of ec2 instance as per region"""
    try:
        client = boto3.client('resourcegroupstaggingapi', region,
                              aws_access_key_id=response['Credentials']['AccessKeyId'],
                              aws_secret_access_key=response['Credentials']['SecretAccessKey'],
                              aws_session_token=response['Credentials']['SessionToken'],
                             )

    except botocore.exceptions.ClientError as err:
        response = {}
        response['isError'] = True
        response['type'] = err.__class__.__name__
        response['message'] = err.message
        raise LambdaError(response)

    try:
        ec2_resources = client.get_resources(
            TagFilters=[
                {
                    'Key':'Name',
                },
            ],
            TagsPerPage=123,
            ResourceTypeFilters=[
                'ec2:instance'
            ]
        )

    except botocore.exceptions.ClientError as err:
        response = {}
        response['isError'] = True
        response['type'] = err.__class__.__name__
        response['message'] = err.message
        raise LambdaError(response)

    total_result.append(process_each_ec2tagkeyvaluepair(ec2_resources, region))
    #return total_result

def lambda_handler(event, context):
    """ Check tesco standard rules"""
    re_task_list = []
    role_arn = 'arn:aws:iam::'+str(event['account_id'])+':role/tesco-app-compliance'
    print ("INFO: Assuming the role of cross Account")

    try:
        response = boto3.client('sts').assume_role(
            DurationSeconds=900,
            RoleArn=role_arn,
            RoleSessionName='iam_user_compliance'
        )

    except botocore.exceptions.ClientError as err:
        response = {}
        response['isError'] = True
        response['type'] = err.__class__.__name__
        response['message'] = err.message
        raise LambdaError(json.dumps(response))

    try:
        client = boto3.client('ec2',
                              aws_access_key_id=response['Credentials']['AccessKeyId'],
                              aws_secret_access_key=response['Credentials']['SecretAccessKey'],
                              aws_session_token=response['Credentials']['SessionToken'],
                              #aws_session_token=None,
                             )

    except botocore.exceptions.ClientError as err:
        response = {}
        response['isError'] = True
        response['type'] = err.__class__.__name__
        response['message'] = err.message
        raise LambdaError(response)

    regions = [region['RegionName'] for region in client.describe_regions()['Regions']]
    response_posblevalue_status.clear()
    del total_result[:]
    for region in regions:
        re_task = Thread(target=list_ec2instance_per_region, args=(region, response))
        re_task.start()
        re_task_list.append(re_task)
    for re_task in re_task_list:
        re_task.join()
    
    print("total result",type(total_result))
    output_response['data'] = total_result
    if output_response['status']:
        output_response['message'] = "This account is COMPLIANT as all ec2 resources present in this account are tagged with tesco standard tags"
    else:
        output_response['message'] = "This account is NON-COMPLIANT as all ec2 resources present in this account are not tagged with tesco standard tags"
        print("These instances tags are not following tesco standards or mandatory tag does not exit", response_tagstd_status)
        print("These instances tag values not matched as per tesco  possible value standard", response_posblevalue_status)
    return output_response


