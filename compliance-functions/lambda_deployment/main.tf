resource "aws_lambda_function" "test_lambda" {
  count   	   = "${var.lambda_functions_count}"
  filename         = "${var.lambda_functions_folder}${trimspace(element(split(";",var.lambda_functions), count.index))}.zip"
  function_name    = "${replace(element(split(";",var.lambda_functions), count.index), "/(^[^a-zA-Z]{1,1}|[^-a-zA-Z0-9_]+)/","")}" 
  role             = "${aws_iam_role.tesco-compliance-lambda-execute.arn}"
  handler          = "${trimspace(element(split(";",var.lambda_functions), count.index))}.lambda_handler"
  source_code_hash = "${base64sha256(file("${var.lambda_functions_folder}${trimspace(element(split(";",var.lambda_functions), count.index))}.zip"))}"
  runtime          = "python2.7"
  publish          =  true
  timeout          =  60
  memory_size      =  512
  tags {
     "tesco_environment_class"="${var.lambda_alias}"
     "tesco_application"="complaince_lambda"
     "tesco_tier"="api"
     "tesco_version"="1.0.0"
     "tesco_status"="active"
     "tesco_service_id"="lambda_functions"
     "tesco_importance"="high"
     "tesco_review_date"="16/08/2017" 
       }
}

output "lambda_arns" {
  value = ["${aws_lambda_function.test_lambda.*.arn}"]
}

output "lambda_versions" {
  value = ["${aws_lambda_function.test_lambda.*.version}"]
}

output "invoke_arns" {
 value = ["${aws_lambda_function.test_lambda.*.invoke_arn}"]
}

resource "aws_lambda_alias" "test_alias" {
  count            = "${var.lambda_functions_count}"
  name             = "${var.lambda_alias}"
  description      = "description"
  function_name    = "${element(aws_lambda_function.test_lambda.*.function_name, count.index)}"
  function_version = "${element(aws_lambda_function.test_lambda.*.version, count.index)}"
}
