# Compliance Check Identity Provider

A Lambda function that checks whether identity provider TescoADFS is present on the specified account and it have valid creation date and returns the validation status as json. This TescoADFS identity provider enables SAML Integration to the Tesco Global Active Directory.

 The function has been run on Python 3.6.

## Pre-requisites

A payload with the following data;

```json
{
  "account_id": "2223344422"
}
```

Below environment variables are expected to be set, if not then defaults are used.

```
SPLUNK_ROLE
VALID_IDP_DATE
```
## Testing using *emulambda*
The event.json will act as the test payload which is consumed by the function when running *emulambda*.
We will be presented with one of the below response as json in the console.

e.g.
`emulambda compliance_check_identity_provider.lambda_handler ./event.json`

## Response

If TescoADFS Identity Provider is found and was created after 28 April 2017, it would provide the below response.

```json
{
  "data": {
    "identityprovider": true,
    "validcreationdate": true
  },
  "status": true,
  "message": "This account has valid TescoADFS identity provider"
}
```

If TescoADFS Identity Provider is not found, it would provide the below response.

```json
{
  "data": {
    "identityprovider": false,
    "validcreationdate": false
  },
  "status": false,
  "message": "TescoADFS Identity provider  not found"
}
```

If TescoADFS Identity Provider is found, but it was not updated after 28 April, it would provide the below response.

```json
{
  "data": {
    "identityprovider": true,
    "validcreationdate": false
  },
  "status": false,
  "message": "TescoADFS Identity provider  found, but invalid creation date"
}
```
## Deployment

Zip the directory content, not the directory. The contents of the Zip file are available as the current working directory of the Lambda function. For example: /project-dir/codefile.py/lib/yourlibraries

From the command shell run the following;
```
function_name="Compliance_Check_identity_Provider"
handler_name="compliance_check_identity_provider.lambda_handler"
package_file=compliance_check_identity_provider.zip
runtime=python3.6
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --description "The function checks whether TescoADFS identity provider exists with valid creation date and returns status as json" \
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
