variable "aws_region" {
  default = "us-east-1"
}
variable "account_id" {
  default = "834873887160"
}

variable "lambda_functions" {
  default = <<EOF
  compliance_check_cis_rules;
  compliance_check_cloud_trail;
  compliance_check_compliance_role;
  compliance_check_ec2_tagging;
  compliance_check_identity_provider;
  compliance_check_standard_roles_policies
EOF
}

variable "lambda_functions_folder" {
  default = "lambda_functions/"
}

variable "lambda_functions_count"{
 default = 6
}
variable "version"{
 default = "1"
}
variable "lambda_alias"{
  default = <<EOF
  Stage;
  NonProd;
  Prod
EOF
}
