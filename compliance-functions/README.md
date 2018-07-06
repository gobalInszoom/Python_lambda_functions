# AWS CCC Lambda Functions



|Functions|Description|
|---|---|
|aws_temp_keys_generator | This allows to generate the access, secret key along with session token for the specified SAML integrated account using the provided AD credentials |
|integrate_splunk | This creates the tesco-splunk-read role on the specified account using the provided keys which is used for collecting data for compliance  |
|compliance_check_standard_roles_policies | This function checks if the default roles and policies are present. It checks if any additional policy is been attached. It also checks if the attached standard policy is been modified  |
|compliance_provision_standard_roles_policies | This particular function will act as a remediation in case of absence of the standard roles and policies, thus creating them in the given account  |
|compliance_check_identity_provider | This checks whether TescoADFS identity provider is present on the specified account|
|compliance_check_cloud_trail | This checks whether cloud trail has enabled in account and correct production bucket is configured with trail|
|compliance_check_cis_rules | This checks if all the tesco standard cis rules are present in the target account and returns the evaluation status as json note: Any new CIS rule that is getting deployed to PRODUCTION, should be added to this file **compliance_check_cis_rules/tesco-config-rules.txt**|
|compliance_check_compliance_role | This function validates tesco-app-compliance role on the account specified in the invoking event for compliance  |
|compliance_provision_config_rules | A Lambda function that creates the tesco standard CIS rules on the target account|
|compliance_check_ec2_tagging | Lambda function that checks all ec2 both tagged non tagged  resources that doesn’t match the tesco standard on specified account  |


P.S. Please add any new functions and their description to the above tables if it is checked-in.

## Recommended Use

Use `emulambda` to emulate the AWS Lambda API locally. It provides a Python "harness" that you can use to wrap your
function and run/analyze it.

Use Vagrant to run the Lambda functions isolated from your workstation. (VagrantFile in project directory)

## Usage

In the root of this folder;

```
vagrant up
vagrant ssh
cd /vagrant/<lambda+folder>
```

From the function root directory, run:
`emulambda -v example.example_handler example.json`


You should see output similar to the following:
```
Executed example.example_handler
Estimated...
...execution clock time:		 277ms (300ms billing bucket)
...execution peak RSS memory:	 368M (386195456 bytes)
----------------------RESULT----------------------
value1
```

Once tested in Dev & Pre-Prod - The required function should be deployed via the AWS CLI to the Production account.

## Security

NEVER store credentials and sensitive data in the event file.
