# Provisioning Standard Roles and Policies

This particular function will act as a remediation in case of absence of the standard roles and policies, thus creating them in the given account.
The entire function is written in python 2.7

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

## Output

In case of successful creation of standard roles and policies, the following output can be observed.

```json
{
  "status": true,
  "message": "Successfully created the roles and policies",
  "data": {
    "total_roles_created": 3,
    "total_policies_create": 4,
    "roles_created": [
      {
        "name": "tesco-app-productowner"
      },
      {
        "name": "tesco-app-developer"
      },
      {
        "name": "tesco-app-tester"
      }
    ],
    "policy_created": [
      {
        "name": "tesco-read-route53"
      },
      {
        "name": "tesco-full-ec2-access"
      },
      {
        "name": "tesco-full-s3-access"
      },
      {
        "name": "tesco-full-route53-access"
      }
    ]
  }
}
```

In case if all the standard roles and policies are present, the following output can be observed.

```json
{
  "status": false,
  "message": "All roles and policies exist. Hence no action is taken",
  "data": []
}
```

In case of improper permissions, invalid account id or some other exceptions, similar kind of response can be observed.

```json
{
  "isError": true,
  "message": "An error occurred (AccessDenied) when calling the GetRole operation: User: arn:aws:iam::096910479567:user/vinay is not authorized to perform: iam:GetRole on resource: role tesco-app-productowner",
  "type": "ClientError"
}
```


##  Testing
The event.json will act as the test payload which is consumed by the function when running *emulambda*.
Run the below command, if all goes well, we will be presented with the compliance role provisioning status as json in the console.

#### Command for testing:
`emulambda compliance_provision_standard_role_policies.lambda_handler - -v < event.json`

## Deployment

Zip the content of the project root directory excluding the project root directory, which is the deployment package.

##### Important
Zip the directory content and not the directory.
Contents of the Zip file will be available as working directory of the Lambda function.

From the command shell run the following;
```
function_name="Compliance_Provision_Standard_Role_Policies"
handler_name="compliance_provision_standard_role_policies.lambda_handler"
package_file=compliance_provision_standard_role_policies.zip
runtime=python2.7
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --description "This function provisions the standard roles and policies in its absence" \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/$role \
  --zip-file fileb://$package_file
  --publish
  --region eu-west-1
```

#### PyLint Rating
```
Global evaluation
-----------------------------------
Your code has been rated at 9.70/10 
```
