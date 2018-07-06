provider "aws" {
  region = "${var.aws_region}"
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/tesco-compliance-lambda-deployment"
    session_name = "SESSION_NAME"
    external_id  = "EXTERNAL_ID"
  }
}

resource "aws_iam_role" "temp-lambda-test" {
    name = "temp-lambda-test"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


data "aws_iam_policy_document" "temp-lambda-test" {

    statement{ 
            "actions"= [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
		"sts:AssumeRole"
            ],
            "resources"= ["*"]
   } 
      
}

resource "aws_iam_policy" "temp-lambda-test" {
    name = "temp-lambda-test"
    path = "/"
    policy = "${data.aws_iam_policy_document.temp-lambda-test.json}"
}

resource "aws_iam_role_policy_attachment" "temp-lambda-test" {
    role       = "${aws_iam_role.temp-lambda-test.name}"
    policy_arn = "${aws_iam_policy.temp-lambda-test.arn}"
}


output "lambda_role_arn"{
  value = ["${aws_iam_role.temp-lambda-test.arn}"]
}
