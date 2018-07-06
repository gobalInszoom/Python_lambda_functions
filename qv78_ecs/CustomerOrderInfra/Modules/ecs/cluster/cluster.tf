variable "owner"                { }
variable "project"              { }
variable "environment"          { }
variable "vpc_id"               { }
variable "private_subnet_ids"   { }
variable "bastion_private_ip"    { }
variable "public_subnet_ids"    { }
variable "ecs_instance"         {
    type="map"
    default = {}
}
variable "availability_zone"    { }

resource "aws_ecs_cluster" "cluster" {
  name = "tf-${var.environment}-${var.project}-cluster"
}

module "alb" {
    source              = "./../alb/"
    owner               = "${var.owner}"
    project             = "${var.project}"
    environment         = "${var.environment}"
    vpc_id              = "${var.vpc_id}"
    public_subnet_ids   = "${var.public_subnet_ids}"
    private_subnet_ids  = "${var.private_subnet_ids}"
}

module "iam" {
    source              = "./../iam/"
    environment         = "${var.environment}"
}

module "asg" {
    source              = "./../asg/"
    owner               = "${var.owner}"
    project             = "${var.project}"
    environment         = "${var.environment}"
    vpc_id              = "${var.vpc_id}"
    private_subnet_ids  = "${var.private_subnet_ids}"
    bastion_private_ip   = "${var.bastion_private_ip}"
    ecs_alb_sg_id       = "${module.alb.ecs_alb_sg_id}"
    ecs_instance        = "${var.ecs_instance}"
    ecs_instance_profile= "${module.iam.ecs_instance_profile}"
    availability_zone   = "${var.availability_zone}"
    cluster_name        = "${aws_ecs_cluster.cluster.name}"
}

#Cluster name
output "cluster_name"       {     value = "${aws_ecs_cluster.cluster.name}"  }
output "cluster_id"         {     value = "${aws_ecs_cluster.cluster.id}"   }

# ALB
output "alb_dns"             {    value = "${module.alb.alb_dns}"                       }
output "target_group_id"     {    value = "${module.alb.target_group_id}"           }
output "ecs_alb_sg_id"       {    value = "${module.alb.ecs_alb_sg_id}"               }

#IAM
output "ecs_instance_profile" {   value = "${module.iam.ecs_instance_profile}"          }
output "ecs_service_role_arn" {   value = "${module.iam.ecs_service_role_arn}"  }
#output "ecs_service_role_policy" {      value = "${module.iam.ecs_service_role_policy}"  }
