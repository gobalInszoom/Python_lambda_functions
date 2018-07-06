#--------------------------------------------------------------
# This module creates all resources necessary for a Bastion
# host
#--------------------------------------------------------------
variable "owner"                { }
variable "project"              { }
variable "environment"          { }
variable "vpc_cidr_block"       { }
variable "vpc_id"               { }
variable "public_subnet_ids"    { }
variable "bastion_host"              {
  type="map"
  default = {}
}


resource "aws_security_group" "bastion_sg" {

    name                       = "tf-${var.environment}-bastion-sg"
    vpc_id                     = "${var.vpc_id}"
    description                = "Bastion security group"
    tags {
        Name                   = "tf-${var.environment}-bastion-sg"
        owner                  = "${var.owner}"
        tesco_environment_class= "${var.environment}"
        tesco_application      = "${var.project}"
        tesco_version          = "1.0.0"
        tesco_status           = "active"
        tesco_importance       = "minor"
   }

    lifecycle { create_before_destroy = true }

    ingress {
      protocol    = -1
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["${var.vpc_cidr_block}"]
    }

    ingress {
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      protocol    = -1
      from_port   = 0
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_instance" "bastion" {
    ami                         = "${var.bastion_host.["ami"]}"
    instance_type               = "${var.bastion_host.["instance_type"]}"
    subnet_id                   = "${element(split(",", var.public_subnet_ids), 0)}"
    key_name                    = "${var.bastion_host.["key_name"]}"
    vpc_security_group_ids      = ["${aws_security_group.bastion_sg.id}"]
    associate_public_ip_address = true
    tags {
        Name                   = "tf-${var.environment}-bastion"
        owner                  = "${var.owner}"
        tesco_environment_class= "${var.environment}"
        tesco_application      = "${var.project}"
        tesco_version          = "1.0.0"
        tesco_status           = "active"
        tesco_importance       = "minor"
   }
    lifecycle { create_before_destroy = true }
}


output "private_ip" { value = "${aws_instance.bastion.private_ip}"  }
output "public_ip"  { value = "${aws_instance.bastion.public_ip}"   }
