variable "owner"                { }
variable "project"              { }
variable "environment"          { }
variable "vpc_id"               { }
variable "bastion_private_ip"   { }
variable "ecs_alb_sg_id"        { }

variable "cluster_name"         { }
variable "ecs_instance"         {
    type="map"
    default = {}
}
variable "ecs_instance_profile" { }
variable "availability_zone"    { }
variable "private_subnet_ids"   { }

resource "aws_security_group" "ecs_instance" {
    name            = "tf-${var.environment}-ecs-instance-sg"
    description     = "Allows all traffic"
    vpc_id          = "${var.vpc_id}"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.bastion_private_ip}/32"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = ["${var.ecs_alb_sg_id}"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags {
        Name                    = "tf-${var.environment}-ecs-instance-sg"
        owner                   = "${var.owner}"
        tesco_environment_class = "${var.environment}"
        tesco_application       = "${var.project}"
        tesco_version           = "1.0.0"
        tesco_status            = "active"
        tesco_importance        = "minor"
    }
}

resource "aws_launch_configuration" "ecs_lc" {

    name_prefix                 = "${var.cluster_name}-instance-lc-"
    image_id                    = "${var.ecs_instance["ami"]}"
    instance_type               = "${var.ecs_instance["instance_type"]}"
    key_name                    = "${var.ecs_instance["key_name"]}" # TODO: is there a good way to make the key configurable sanely?
    security_groups             = ["${aws_security_group.ecs_instance.id}"]
    iam_instance_profile        = "${var.ecs_instance_profile}"
    associate_public_ip_address = false
    lifecycle {
        create_before_destroy   = true
    }
    user_data = "#!/bin/bash\necho ECS_CLUSTER='${var.cluster_name}' > /etc/ecs/ecs.config"

    # name_prefix             = "${var.cluster_name}-instance"
    /*ebs_block_device {
        device_name             = "/dev/sda1"
        delete_on_termination   = false
    }       */

    #root_block_device
    #ebs_block_device
}

resource "aws_autoscaling_group" "ecs_cluster" {
    availability_zones      = ["${split(",", var.availability_zone)}"]
    name                    = "${var.cluster_name}-instance-asg"
    min_size                = "${var.ecs_instance["min"]}"
    max_size                = "${var.ecs_instance["max"]}"
    desired_capacity        = "${var.ecs_instance["desired"]}"
    health_check_type       = "EC2"
    launch_configuration    = "${aws_launch_configuration.ecs_lc.name}"
    vpc_zone_identifier     = ["${split(",", var.private_subnet_ids)}"]
    lifecycle { create_before_destroy = true }
    tag {
        key     = "Name"
        value   = "${var.cluster_name}-instance"
        propagate_at_launch = true
    }

    #depends_on = ["aws_launch_configuration.ecs_lc.name"]
}

/* tags {
        Name                    = "tf-${var.environment}-ecs-instance-asg"
        owner                   = "${var.owner}"
        tesco_environment_class = "${var.environment}"
        tesco_application       = "${var.project}"
        tesco_version           = "1.0.0"
        tesco_status            = "active"
        tesco_importance        = "minor"
    }  */
