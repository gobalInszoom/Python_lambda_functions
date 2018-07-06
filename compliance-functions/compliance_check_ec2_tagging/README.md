# Check both tagged and non-tagged ec2 resources that don’t match the standard

A Lambda function that checks both tagged and non tagged EC2 resources that doesn't match the tesco standard  and returns the validation status as json, The function has been run on Python 2.7

## Pre-requisites

Input from event.json
```
{
  "account_id": "834873887160"
}
```
Rules for Tesco standard tagging stratergy

```
please refer the below URL https://github.dev.global.tesco.org/pages/97CoreDevOpsTools/AWS-Standards/general-management/tagging-strategy/
```
##  Testing
The event.json will act as the test payload which is consumed by the function when running *emulambda*.

`emulambda compliance_check_ec2_tagging.lambda_handler - -v < event.json`

Output json
```json
RESULT
-------
If all the ec2 tags  are validated against tesco standard  in the remote account succeeded, then we get the following output:
{
  "status": true,
  "message": "This account is COMPLIANT as all ec2 resources present in this account are tagged with   tesco standard tags"
}

If all the ec2 tags  are validated against tesco standard   in the remote account fails, then we get output similar to the below:
{
  "status": false,
  "data": [
    {
      "eu-west-2": {
        "non_compliant_instances": [],
        "compliant_instances": []
      }
    },
    {
      "eu-west-1": {
        "non_compliant_instances": [
          "i-0f4e8bf7d7e2fdf19",
          "i-02750c8bdeba6fa1c",
          "i-002f9c1b4abfd7333",
          "i-0b78906feb1d67acd",
          "i-0c39ef4a0962c6b2c",
          "i-0a38dad588d9a9744"
        ],
        "compliant_instances": []
      }
    },
    {
      "ap-south-1": {
        "non_compliant_instances": [],
        "compliant_instances": []
      }
    },
    {
      "ap-northeast-1": {
        "non_compliant_instances": [],
        "compliant_instances": []
      }
    },
  "message": "This account is NON-COMPLIANT as all ec2 resources present in this account are not tagged with  tesco standard tags"
}

```

## Deployment

Zip the content of the project-dir directory which includes lambda function.py and event.json. From the command shell run the following
```
function_name="Compliance_Check_ec2_tagging"
handler_name="Compliance_Check_ec2_tagging.lambda_handler"
package_file=Compliance_Check_ec2_tagging.zip
runtime=python3.6
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 15 \
  --description "The function that checks both tagged and non-tagged resources that don’t match the standard " \
  --role arn:aws:iam::$account_id:role/$role \
  --zip-file fileb://$package_file
```

### PyLint Rating
```
Global evaluation
-----------------
Your code has been rated at 9.02/10
```
