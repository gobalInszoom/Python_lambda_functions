# Check If default IAM roles and policies are present

A Lambda function that checks if all the tesco default aws roles and policies are present in the target account and returns the evaluation status as json, The function has been run on Python 2.7

## Pre-requisites

Input from event.json
```json
{
  "account_id": "834873887160"
}
```
and
All json policies are grouped based on roles and packaged along with the lambda.


##  Testing
The event.json will act as the test payload which is consumed by the function when running *emulambda*.

`emulambda compliance_check_standard_roles_policies.lambda_handler - -v < event.json`

Output json
```json
{
  "status": false,
  "message": "Account is non-compliant with the standard roles and policies",
  "data": [
    {
      "role": "tesco-app-admin",
      "present": true,
      "custom_policies": [],
      "non_compliant_policies": [],
      "missing_policies": []
    },
    {
      "role": "tesco-app-tester",
      "present": true,
      "custom_policies": [
        {
          "name": "tesco_read_route53"
        },
        {
          "name": "tesco_read_s3"
        }
      ],
      "non_compliant_policies": [
        {
          "name": "tesco-read-ec2"
        }
      ],
      "missing_policies": [
        {
          "name": "tesco-full-route-53-access"
        },
        {
          "name": "tesco-full-s3-access"
        }
      ]
    },
    {
      "role": "tesco-app-developer",
      "present": true,
      "custom_policies": [
        {
          "name": "Tesco_compliance_access"
        },
        {
          "name": "Tesco_CloudFormation_createstack"
        }
      ],
      "non_compliant_policies": [
        {
          "name": "tesco-full-s3-access"
        },
        {
          "name": "tesco-full-ec2-access"
        }
      ],
      "missing_policies": []
    },
    {
      "role": "tesco-app-productowner",
      "present": true,
      "custom_policies": [],
      "non_compliant_policies": [],
      "missing_policies": []
    }
  ]
}
```

## Deployment

Zip the content of the project-dir directory which includes policies based on roles which are in json format,lambda function,hashlib,queue,event.json.From the command shell run the following
```
function_name="Compliance_Check_Standard_Roles_Policies"
handler_name="compliance_check_standard_roles_policies.lambda_handler"
package_file=compliance_check_standard_roles_policies.zip
runtime=python2.7
aws lambda create-function \
  --function-name $function_name \
  --handler $handler_name \
  --runtime $runtime \
  --memory 512 \
  --timeout 60 \
  --description "The function that checks default tesco standard aws roles and polices validation" \
  --role arn:aws:iam::$account_id:role/$role \
  --zip-file fileb://$package_file
```

### PyLint Rating
```
Global evaluation
-----------------
Your code has been rated at 9.57/10
```


