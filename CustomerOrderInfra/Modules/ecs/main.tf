variable "owner"                { }
variable "project"              { }
variable "environment"          { }
variable "vpc_id"               { }
variable "public_subnet_ids"    { }
variable "private_subnet_ids"   { }
variable "repository_name" 		{ }
variable "bastion_private_ip"    { }
variable "ecs_instance" 		{
	type="map"
	default = {}
}
variable "availability_zone"   { }
resource "aws_ecr_repository" "ecr" {
  name = "tf-${var.environment}-${var.repository_name}"
}

module "cluster" {
	source 				= "./cluster/"
	owner               = "${var.owner}"
	project				= "${var.project}"
	environment         = "${var.environment}"
   	vpc_id 				= "${var.vpc_id}"
   	public_subnet_ids   = "${var.public_subnet_ids}"
    private_subnet_ids	= "${var.private_subnet_ids}"
    bastion_private_ip	= "${var.bastion_private_ip}"
	ecs_instance 		= "${var.ecs_instance}"
	availability_zone   = "${var.availability_zone}"
}

module "task-definition" {
	source 				= "./task_definition/"
	project				= "${var.project}"
	environment         = "${var.environment}"
}


module "service" {
	source 				= "./service/"
	project				= "${var.project}"
	environment         = "${var.environment}"
	cluster_name		= "${module.cluster.cluster_name}"
	cluster_id			= "${module.cluster.cluster_id}"
	ecs_service_role_arn= "${module.cluster.ecs_service_role_arn}"
	target_group_id		= "${module.cluster.target_group_id}"
	ecs_task_definition_arn = "${module.task-definition.ecs_task_definition_arn}"
	ecs_task_family 	= "${module.task-definition.ecs_task_family }"
	ecs_task_revision 	= "${module.task-definition.ecs_task_revision }"
	#ecs_service_role_policy = "${{module.cluster.ecs_service_role_policy}"
}


output "ecs_repo_url" 	     {  value = "${aws_ecr_repository.ecr.repository_url}"  }


output "cluster_name"        {   value = "${module.cluster.cluster_name}" 		 }

# ALB
output "alb_dns"             {    value = "${module.cluster.alb_dns}"                   }
output "target_group_id"     {    value = "${module.cluster.target_group_id}"           }
output "ecs_alb_sg_id"       {    value = "${module.cluster.ecs_alb_sg_id}"             }

#IAM
output "ecs_instance_profile" {   value = "${module.cluster.ecs_instance_profile}"          }
output "ecs_service_role_arn" {   value = "${module.cluster.ecs_service_role_arn}"  }

#output "ecs_service_role_policy" {      value = "${module.cluster.ecs_service_role_policy}"  }

output "ecs_task_definition_arn" { value = "${module.task-definition.ecs_task_definition_arn}"}
output "ecs_task_revision" { 	value = "${module.task-definition.ecs_task_revision }" }
output "ecs_task_family" { 	value = "${module.task-definition.ecs_task_family }" }
