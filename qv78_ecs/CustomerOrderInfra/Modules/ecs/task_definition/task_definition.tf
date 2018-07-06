variable "project"              { }
variable "environment"          { }



resource "aws_ecs_task_definition" "app_task_definition" {
    family				  = "${var.environment}-app"
    container_definitions = "${file("../policies/app-task-definition.json")}"
    volume {
    name = "my-vol"
    #host_path = "/ecs/service-storage"
    #C:/Users/vagrant/Desktop/myRepo/ecs-terraform/modules/ecs/task_definition/
  }
}

output "ecs_task_definition_arn" { 	value = "${aws_ecs_task_definition.app_task_definition.arn}" 		}
output "ecs_task_revision" 		 { 	value = "${aws_ecs_task_definition.app_task_definition.revision }" 	}
output "ecs_task_family" 		 { 	value = "${aws_ecs_task_definition.app_task_definition.family }" 	}
