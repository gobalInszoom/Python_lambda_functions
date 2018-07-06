# Check If CIS Rules are Applied

A Lambda function that checks if all the tesco standard cis rules are present in the target account and returns the evaluation status as json, The function has been run on Python 2.7

## Pre-requisites

Input from event.json
```
{
  "account_id": "2223344422"
}
```
File tesco-cis-rules.txt which has all the names of the latest CIS Rules deployed in PROD as below

```
CIS_Tesco_Policy_-_IAM_MFA_Enabled,CIS_Tesco_Policy_-_Password_Policy-T,CIS_Tesco_Policy_-_IAM_MFA_Local_User_Required-T,CIS_Tesco_policy_-_IAM_Local_User,CIS_Tesco_Policy_-_IAM_Access_Key_Root_Disabled-P,CIS_Tesco_Policy_-_IAM_MFA_Root-P,CIS_Tesco_Policy_-_Inactive_User,CIS_Tesco_Policy_-_Cloudtrail_Validation_All_Regions-P,CIS_Tesco_Policy_-_EC2-Exposed,CIS_Tesco_Policy_-_IAM_Access_Key_Rotation-T,CIS_Tesco_Policy_-_Cloudtrail_All_Regions_Enabled-P
```
##  Testing
The event.json will act as the test payload which is consumed by the function when running *emulambda*.

`emulambda compliance_check_cis_rules.lambda_handler - -v < event.json`

Output json
```json
RESULT
-------
{
  "status": false,
  "message": "Account is NONCOMPLIANT as all the tesco standard CIS rules are not present",
  "data": {
    "CIS_Tesco_Policy_-_IAM_Access_Key_Rotation-T": false,
    "CIS_Tesco_Policy_-_EC2-Exposed": false,
    "CIS_Tesco_Policy_-_IAM_Access_Key_Root_Disabled-P": false,
    "CIS_Tesco_Policy_-_IAM_MFA_Local_User_Required-T": false,
    "CIS_Tesco_Policy_-_Inactive_User": false,
    "CIS_Tesco_Policy_-_Cloudtrail_Validation_All_Regions-P": false,
    "CIS_Tesco_policy_-_IAM_Local_User": false,
    "CIS_Tesco_Policy_-_IAM_MFA_Enabled": false,
    "CIS_Tesco_Policy_-_Password_Policy-T": false,
    "CIS_Tesco_Policy_-_Cloudtrail_All_Regions_Enabled-P": false,
    "CIS_Tesco_Policy_-_IAM_MFA_Root-P": false
  }
}
```

## Deployment

Zip the content of the project-dir directory which includes tesco-cis-rules.txt,lambda function.py and event.json. From the command shell run the following
```
function_name="Compliance_Check_CIS_Rules"
handler_name="compliance_check_cis_rules.lambda_handler"
package_file=compliance_check_cis_rules.zip
runtime=python2.7
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --description "The function that checks cis rules validation " \
  --role arn:aws:iam::$account_id:role/$role \
  --zip-file fileb://$package_file
```

### PyLint Rating
```
Global evaluation
-----------------
Your code has been rated at 10/10
```
