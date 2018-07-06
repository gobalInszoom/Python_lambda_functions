# Validate Clud Trail enabled

A Lambda function that validates whether cloudtrail has enabled on the specified account and returns the validation status as json, The function has been run on Python 3.6

## Pre-requisites

A payload with the following data;

```
{
  "AccountID": "2223344422"
}
```
## Testing using *emulambda*
The event.json will act as the test payload which is consumed by the function when running *emulambda*.
We will be presented with one of the below response as json in the console.

e.g.
`emulambda compliance_check_cloud_trail.lambda_handler ./event.json`

## Response

If Cloud trail is enabled in a account and correct bucket has setup, it would provide the below response.

```
{
  "status": "True",
  "message": "This account is compliant with Cloud Trail",
  "data": {
    "logs_in_central_s3": true,
    "cloudtrail_enabled_all_region": true
  }
}
```

If Cloud trail is not enabled in a account and correct bucket has not setup, it would provide the below response.

```
{
{
  "status": "True",
  "message": "This account is not compliant with Cloud Trail",
  "data": {
    "logs_in_central_s3": false,
    "cloudtrail_enabled_all_region": false
  }
}
```


## Deployment

Zip the directory content, not the directory. The contents of the Zip file are available as the current working directory of the Lambda function. For example: /project-dir/codefile.py/lib/yourlibraries

From the command shell run the following;
```
function_name="compliance_Check_Cloud_Trailr"
handler_name="compliance_check_cloud_trail.lambda_handler"
package_file=compliance_check_cloud_trail.zip
runtime=python2.7
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
Hello
Global evaluation
-----------------
Your code has been rated at 9.16/10
```


