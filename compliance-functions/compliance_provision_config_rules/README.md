# Compliance Provision Config Rules

A Lambda function that creates the tesco standard CIS rules on the target account if it is not available. The configuration details regarding each config rule are available in ```config-rule-metadata.json```file and the respective lambda functions are located at ```./rules/```


## Pre-requisites

A payload with the following data;

```json
{
  "account_id": "123456789012",
  "access_key": "xzxzxzxzxzxzxzxz",
  "secret_key": "xzxzxzxzxzxzxzxz",
  "session_token": "xzxzxzxzxzxzxzxz"
}
```


## To add new to config rule

- Add the respective lambda function (.py file ) under ```./rules/```
- Update ```config-rule-metadata.json``` file with config rule details as below. Make sure ```config-rule-metadata.json``` file is in proper json format

```json
"Compliance_Check_EC2_Exposed": [{
          "run_time":"python2.7",
          "handler_name":"compliance_check_ec2_exposed",
          "description":"Compliance_Check_EC2_Exposed",
          "input_parameters":{
                            "RDP": "3389",
                            "SSH": "22"
                              },
          "trigger_type": "ConfigurationItemChangeNotification",
          "resource_type": ["AWS::IAM::User"],
          "tags": {
                  "tesco_tier":"api"
          }
  }]
```

## Testing using *emulambda*
The event.json will act as the test payload which is consumed by the function when running *emulambda*.

We will be presented with one of the below response as json in the console.

e.g.
`emulambda compliance_provision_config_rules.lambda_handler ./event.json`

## Response

If all the tesco standard cis rules are present in the target account, this function provides below response

```json
{"status": false, "message": "Configuration rules are already present, no action taken", "data": {"created_rules_total": 0, "existing_rules_total": 8, "failed_rules_total": 0, "created_rules_name": [], "existing_rules_name": ["Compliance_Check_IAM_Root_MFA_Enabled", "Compliance_Check_EC2_Exposed", "Compliance_Check_IAM_Active_Root_Access_Key", "Compliance_Check_IAM_Inactive_User", "Compliance_Check_IAM_Local_MFA_Enabled", "Compliance_Check_IAM_User_Password_Policy", "Compliance_Check_CloudTrail_All_Region_Enabled", "Compliance_Check_IAM_Local_Access_Key_Rotation"], "failed_rules_name": [], "rollback_message": "no rollback needed", "custom_message": "config rules are already present. No action taken"}}

```

If one or more cis rules have to be created on the target account, this function creates it and provides below response

```json
{"status": true, "message": "Configuration rules are created successfully", "data": {"created_rules_total": 4, "existing_rules_total": 4, "failed_rules_total": 0, "created_rules_name": ["Compliance_Check_IAM_Root_MFA_Enabled", "Compliance_Check_CloudTrail_All_Region_Enabled", "Compliance_Check_IAM_Local_MFA_Enabled", "Compliance_Check_IAM_Local_Access_Key_Rotation"], "existing_rules_name": ["Compliance_Check_IAM_Active_Root_Access_Key", "Compliance_Check_IAM_User_Password_Policy", "Compliance_Check_EC2_Exposed", "Compliance_Check_IAM_Inactive_User"], "failed_rules_name": [], "rollback_message": "no rollback needed", "custom_message": "config rules are created successfully"}}
```

If there is any error while creating cis rule or lambda function in the target account, it rolls back the new changes and provides below response

```json
{"status": false, "message": "Configuration rules creation is failed", "data": {"created_rules_total": 1, "existing_rules_total": 6, "failed_rules_total": 1, "created_rules_name": ["Compliance_Check_IAM_Local_Access_Key_Rotation"], "existing_rules_name": ["Compliance_Check_IAM_Root_MFA_Enabled", "Compliance_Check_EC2_Exposed", "Compliance_Check_IAM_Active_Root_Access_Key", "Compliance_Check_IAM_Inactive_User", "Compliance_Check_IAM_User_Password_Policy", "Compliance_Check_CloudTrail_All_Region_Enabled"], "failed_rules_name": ["Compliance_Check_IAM_Local_MFA_Enabled"], "rollback_message": "Successfully rolled back created CIS rules", "custom_message": "An error occurred (ResourceConflictException) when calling the CreateFunction operation: Function already exist: Compliance_Check_IAM_Local_MFA_Enabled"}}
```

## Deployment

Zip the directory content, not the directory. The contents of the Zip file are available as the current working directory of the Lambda function. 

From the command shell run the following;
```
function_name="Compliance_Provision_Config_Rule"
handler_name="compliance_provision_config_rule.lambda_handler"
package_file=compliance_provision_config_rule.zip
runtime=python2.7
role="xxxxxxx"
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --description "The function creates Tesco standard CIS rules and 
  returns status as json" \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/$role \
  --zip-file fileb://$package_file
  --publish
  --region eu-west-1
```

#### PyLint Rating
```
Global evaluation
-----------------
Your code has been rated at 9.09/10 (previous run: 9.09/10, +0.00)
```

