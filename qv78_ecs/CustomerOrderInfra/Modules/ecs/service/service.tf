variable "project"              { }
variable "environment"          { }

variable "cluster_name"         { }
variable "cluster_id"           { }
variable "ecs_service_role_arn" { }
variable "ecs_task_definition_arn" { }
variable "target_group_id"     { }
variable "ecs_task_revision"    { }
variable "ecs_task_family"      { }
#variable "container_name"       { }
#variable "container_port"       { }


resource "aws_ecs_service" "app-service" {
    name                 = "tf-app-service"
    cluster              = "${var.cluster_id}"
    task_definition      = "${var.ecs_task_family}:${var.ecs_task_revision}"
    iam_role             = "${var.ecs_service_role_arn}"
    desired_count        = 2
    #placement_strategy { type ="spread"  }
    #depends_on           = ["aws_iam_role_policy.ecs_service_role_policy"]
    deployment_minimum_healthy_percent = 50 # % of the number of running tasks that must remain running and healthy in a service during a deployment
    deployment_maximum_percent         = 100 
    load_balancer {
        target_group_arn = "${var.target_group_id}"
        container_name   = "tf-simple-app" #same as in task-definition.json
        container_port   = 80
    }
   
}

