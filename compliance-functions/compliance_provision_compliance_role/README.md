# Provision Compliance Role and Policy

A Lambda function that provisions the IAM role and attached policies in the specified account and returns the status as json, The function has been run on Python 2.7

## Pre-requisites

A payload with the following data;

```json
{
  "account_id": "223344556677",
  "access_key": "xzxzxzxzxzxzxzxz",
  "secret_key": "xzxzxzxzxzxzxzxz",
  "session_token": "xzxzxzxzxzxzxzxz"
}

```
Below environment variables are expected to be set, if not then defaults are used

```
ROLE_NAME
POLICY_NAME
```

## Output

If provisioning of the IAM role and polic in the remote account succeeds, then we get the following output;

```json
{
    "data": {
        "role_arn": "arn:aws:iam::223344556677:role/role_name",
        "policy_arn": "arn:aws:iam::223344556677:policy/policy_name",
        "default_policy_version": "Vxx",
        "policy_versions": 1
    },
    "message": "Successfully provisioned role and attached policy",
    "status": true
}
```

If provisioning of IAM role in the remote account fails, then lambda function raises exception similar to the below;
any exception raised from the lambda function should be mapped to appropriate http status codes and output model of the method response in API Gateway configuration.

```json
{
    "isError" : true,
    "message" : "Error message from the lambda exception",
    "type": "ErrorType"
}
```


##  Testing
The event.json will act as the test payload which is consumed by the function when running *emulambda*.
Ensure that the policies/${ROLE_NAME}/${POLICY_NAME}.json file is present and contains valid IAM policy
Ensure that the policies/${ROLE_NAME}/${POLICY_NAME}-trust.json file is present and contains valid trust policy
Run the below command, if all goes well, we will be presented with the compliance role provisioning status as json in the console.

`Note:
${POLICY_NAME} here refers to POLICY_NAME environment variable of the lambda function, which if not defined will default to tesco-compliance-read`

#### Command for testing:
`emulambda compliance_provision_compliance_role.lambda_handler ./event.json`

## Versioning & Aliases

In order to keep different versions of the same function we can *Publish a new version* via the command line. We should only change "PROD" alias to a version that has been tested thoroughly. DEV can be pointed to $LATEST version.

#### Creating a new Alias
```
aws lambda create-alias \
--function-name compliance_provision_${ROLE_NAME} \
--decription "Sample alias" \
--function-version "\$LATEST" \
--name DEV
```

#### Updating a version
```
aws lambda update-function-code \
--function-name compliance_provision_${ROLE_NAME}
--zip-file fileb://compliance_provision_compliance_role.zip
```

#### Publishing the version
```
aws lambda publish-version \
--function-name compliance_provision_${ROLE_NAME}
```

#### Update Alias
```
aws lambda update-alias \
--function-name compliance_provision_${ROLE_NAME}
--function-version 2
--name PROD
```

## Deployment

Ensure that the policies/${ROLE_NAME}/${POLICY_NAME}.json file is present and contains valid IAM policy
Ensure that the policies/${ROLE_NAME}/${POLICY_NAME}-trust.json file is present and contains valid trust policy

Zip the content of the project root directory excluding the project root directory, which is the deployment package.

`Note:
${POLICY_NAME} here refers to POLICY_NAME environment variable of the lambda function, which if not defined will default to tesco-compliance-read`

##### Important
Zip the directory content, not the directory.
Contents of the Zip file will be available as working directory of the Lambda function.

From the command shell run the following;
```
function_name="compliance_provision_${ROLE_NAME}"
handler_name="compliance_provision_compliance_role.lambda_handler"
package_file=compliance_provision_compliance_role.zip
runtime=python2.7
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --environment Variables="{ROLE_NAME=tesco-compliance-read,POLICY_NAME=tesco-compliance-read}" \
  --description "This function provisions the compliance role and returns the status as json" \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/$role \
  --zip-file fileb://$package_file
  --publish
  --region eu-west-1
```

#### PyLint Rating
```
Global evaluation
-----------------
Your code has been rated at 8.56/10
```
