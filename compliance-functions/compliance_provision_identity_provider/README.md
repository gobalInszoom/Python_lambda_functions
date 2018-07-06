# Compliance Provision Identity Provider

A Lambda function that creates TescoADFS identity provider on the specified account and updates FederationMetadata document if exisiting metadata updation date is less than 28th April 2017. This function enables SAML Integration to the Tesco Global Active Directory and returns the status as json object.

The function has been run on Python 3.6.

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

Below environment variables are expected to be set, if not then defaults are used.

```json
VALID_IDP_DATE
```

## Testing using *emulambda*
The event.json will act as the test payload which is consumed by the function when running *emulambda*.
We will be presented with one of the below response as json in the console.

e.g.
`emulambda compliance_provision_identity_provider.lambda_handler ./event.json`

## Response

If TescoADFS Identity Provider is not found, and it was created successfully, it would provide the below response.

```json
{
  "data": {},
  "status": true,
  "message": "TescoADFS identity provider was successfully created"
}
```

If TescoADFS Identity Provider is found with valid federatedmetadata document, it would provide the below response.

```json
{
  "data": {},
  "status": false,
  "message": "TescoADFS identity provider was already present, with valid federatedmetadata document"
}
```

If TescoADFS Identity Provider is found, but federatedmetadata document was not updated after 28 April, and it was updated successfully it would provide the below response.

```json
{
  "data": {},
  "status": true,
  "message": "TescoADFS Identity provider was already present, federatedmetadata was successfully updated"
}
```

## Deployment

Zip the directory content, not the directory. The contents of the Zip file are available as the current working directory of the Lambda function. For example: /project-dir/codefile.py/lib/yourlibraries

From the command shell run the following;
```
function_name="Compliance_Provision_Identity_Provider"
handler_name="compliance_provision_identity_provider.lambda_handler"
package_file=compliance_provision_identity_provider.zip
runtime=python3.6
role="tesco-app-compliance"
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --description "The function creates TescoADFS identity provider and updates metadata file if already exists with invalid creation date and returns status as json" \
  --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/$role \
  --zip-file fileb://$package_file
  --publish
  --region eu-west-1
```

#### PyLint Rating
```
Global evaluation
-----------------
Your code has been rated at 10.00/10
```
