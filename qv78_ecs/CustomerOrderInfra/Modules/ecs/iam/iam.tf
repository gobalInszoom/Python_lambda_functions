variable "environment"          { }

# ECS Instance Roles
resource "aws_iam_role" "ecs_instance_role" {
    name               = "tf-${var.environment}-ecs-instance-role"
    assume_role_policy = "${file("../policies/ecs-role.json")}"
}

resource "aws_iam_role_policy" "ecs_instance_role_policy" {
    name               = "tf-${var.environment}-ecs-instance-role-policy"
    policy             = "${file("../policies/ecs-instance-role-policy.json")}"
    role               = "${aws_iam_role.ecs_instance_role.id}"
}

resource "aws_iam_instance_profile" "ecs" {
    name               = "tf-${var.environment}-ecs-instance-main-profile"
    path               = "/"
    roles              = ["${aws_iam_role.ecs_instance_role.name}"]
}

## Serice Role

resource "aws_iam_role" "ecs_service_role" {
    name               = "tf-${var.environment}-ecs-service-role"
    assume_role_policy = "${file("../policies/ecs-role.json")}"
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
    name               = "tf-${var.environment}-ecs-service-role-policy"
    policy             = "${file("../policies/ecs-service-role-policy.json")}"
    role               = "${aws_iam_role.ecs_service_role.id}"
}


output "ecs_instance_profile" { 	value = "${aws_iam_instance_profile.ecs.name}"  }
output "ecs_service_role_arn" {  	value = "${aws_iam_role.ecs_service_role.arn}"  }
#output "ecs_service_role_policy" {  	value = "${aws_iam_role_policy.ecs_service_role_policy.}"  }
