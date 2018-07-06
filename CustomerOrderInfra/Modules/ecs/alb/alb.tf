variable "owner"                { }
variable "project"              { }
variable "environment"          { }
variable "vpc_id"               { }
variable "public_subnet_ids"    { }
variable "private_subnet_ids"   { }


#Creates security group for an ALB
resource "aws_security_group" "alb_sg" {
    name            = "tf-${var.environment}-alb-sg"
    description     = "Allows all traffic"
    vpc_id          = "${var.vpc_id}"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #TODO - only to ECS instances
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
     tags {
        Name                   = "tf-${var.environment}-alb-sg"
        owner                  = "${var.owner}"
        tesco_environment_class= "${var.environment}"
        tesco_application      = "${var.project}"
        tesco_version          = "1.0.0"
        tesco_status           = "active"
        tesco_importance       = "minor"
    }
}

resource "aws_alb_target_group" "main_alb" {

  name                   = "tf-${var.environment}-tg"
  port                   = 80
  protocol               = "HTTP"
  vpc_id                 = "${var.vpc_id}"
  health_check {
    interval             = 6
    path                 = "/"
    timeout              = 5
    healthy_threshold    = 3
    unhealthy_threshold  = 2
  }
}

resource "aws_alb" "main_alb" {
  name                    ="tf-${var.environment}-${var.project}"
  internal                = false
  security_groups         = ["${aws_security_group.alb_sg.id}"]
  subnets                 = ["${split(",", var.public_subnet_ids)}"]
  #enable_deletion_protection = true
  tags {
          Name                    = "tf-${var.environment}-${var.project}-lb"
          owner                   = "${var.owner}"
          tesco_environment_class = "${var.environment}"
          tesco_application       = "${var.project}"
          tesco_version           = "1.0.0"
          tesco_status            = "active"
          tesco_importance        = "minor"
    }
   #cross_zone_load_balancing = true
}


resource "aws_alb_listener" "main_alb" {

    load_balancer_arn = "${aws_alb.main_alb.id}"
    port              = "80"
    protocol          = "HTTP"
    default_action {
     target_group_arn = "${aws_alb_target_group.main_alb.id}"
     type             = "forward"
   }

}

resource "aws_alb_listener_rule" "alb_rule" {

  listener_arn       = "${aws_alb_listener.main_alb.id}"
  priority           = 100
  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.main_alb.id}"
  }
  condition {
    field            = "path-pattern"
    values           = ["/*"]
  }

}


output "alb_dns"             {    value = "${aws_alb.main_alb.dns_name}"                  }
output "target_group_id"     {    value = "${aws_alb_target_group.main_alb.id}"           }
output "ecs_alb_sg_id"       {    value = "${aws_security_group.alb_sg.id}"               }
