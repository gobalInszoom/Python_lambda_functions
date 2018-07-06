resource "aws_elb" "http_elb" {
  name ="${var.elb_name}ELB"
  subnets = ["${var.subnet1_id}", "${var.subnet2_id}"]
  security_groups = ["${var.jenkins_sg_out}"]

  listener {
    instance_port = "${var.port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 4
    timeout = 7
    target = "TCP:${var.port}"
    interval = 15
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  instances = ["${var.instance_id}"]
  tags {
    Owner = "${var.owner}"
    Environment = "${var.environment}"
    Project = "${var.project}"
  }
}
