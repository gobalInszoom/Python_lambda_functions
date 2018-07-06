# Validate Role and Policy

A Lambda function that validates the role and attached policies specified by ROLE_NAME and POLICY_NAME environment variables on the account
This function returns the validation status as json, The function has been run on Python 2.7

## Pre-requisites

A payload with either of the two following data;

```json
{
  "account_id": "834873887160",
  "role_name": "tesco-splunk-read",
  "policy_name": "tesco-read-all",
  "compliance_account": "531973092423"
}
```

**account_id** here refers to 12 digit AWS account number on which the check has to be performed.
**role_name** is the name of the IAM role that has to be checked.
**policy_name** refers to the policy attached to the IAM role.
**compliance_account** is the 12 digit account number of the AWS account that has trust relationship


```json
{
  "account_id": "2223344422"
}

```
**role_name**, **policy_name**, and **compliance_account** default to "tesco-app-compliance", "tesco-app-compliance", and "264005623395" when omitted as in this case



## Output

If validation of the role and attached policy in the remote account succeeds, then we get the following output;

```json
{
    "data": {
        "assumerole": true,
        "attachedpolicy": true,
        "trustpolicy": true
    },
    "message": "role and attached policies are Validated on the account",
    "status": true
}
```

If validation of the role or attached policy faile for some reason, then we get output similar to the below;

```json
{
    "data": {
        "assumerole": true,
        "attachedpolicy": false,
        "trustpolicy": false
    },
    "message": "Trust relationship not found",
    "status": false
}
```


##  Testing
The event.json will act as the test payload which is consumed by the function when running *emulambda*.
Ensure that the policies/${ROLE_NAME}/${POLICY_NAME}.json file is present and contains valid IAM policy, and run the below command
Assuming all goes well, we will be presented with the role validation status as json in the console.

e.g.
`emulambda compliance_check_compliance_role.lambda_handler ./event.json`

##  Unit Test
Running Unit test requires a role or temporary credentials mimicking the actual IAM role with which the compliance role will be provisioned.
Unit test in the current form verifies the roles and policies in tescotechnology account

Running unit test
`python -m unittest discover`

## Versioning & Aliases

In order to keep different versions of the same function we can *Publish a new version* via the command line. We should only change "PROD" alias to a version that has been tested thoroughly. DEV can be pointed to $LATEST version.

#### Creating a new Alias
```
aws lambda create-alias \
--function-name Compliance_Check_Compliance_Role \
--decription "Sample alias" \
--function-version "\$LATEST" \
--name DEV
```

#### Updating a version
```
aws lambda update-function-code \
--function-name Compliance_Check_Compliance_Role
--zip-file fileb://compliance_check_compliance_role.zip
```

#### Publishing the version
```
aws lambda publish-version \
--function-name Compliance_Check_Compliance_Role
```

#### Update Alias
```
aws lambda update-alias \
--function-name Compliance_Check_Compliance_Role
--function-version 2
--name PROD
```

## Deployment

Ensure that the policies/${ROLE_NAME}/${POLICY_NAME}.json file is present and contains valid IAM policy directory,
Zip the content of the project directory excluding the project directory itself, which is the deployment package.

##### Important
Zip the directory content and all its subdirectories recursively, excluding the directory itself.
The contents of the Zip file are available as the current working directory of the Lambda function.
```
zip compliance_provision_compliance_role -r *
```

From the command shell run the following;
```
function_name="Compliance_Check_Compliance_Role"
handler_name="compliance_check_compliance_role.lambda_handler"
package_file=compliance_check_compliance_role.zip
runtime=python2.7
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --environment Variables="{ROLE_NAME=tesco-compliance-read,POLICY_NAME=tesco-compliance-read}" \
  --description "The function that returns the role validation status as json" \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/$role \
  --zip-file fileb://$package_file
  --publish
  --region eu-west-1
```

#### PyLint Rating
```
Global evaluation
-----------------
Your code has been rated at 9.43/10
```
