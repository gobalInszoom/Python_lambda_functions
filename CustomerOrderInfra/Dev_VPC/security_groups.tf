variable "project" {
  description="The project's name or code which the resource(s) belong to."
  default="Demo"
}
variable "owner" {
  description="The project owner(s) name or email address."
}
variable "environment" {
  description="The environment name or code which the resource(s) belong to."
}

resource "aws_security_group" "chef-server-sg" {
  name        = "${var.project}_${var.environment}_ChefServer_sg_${module.vpc.vpc_id_out}"
  description = "Allow SSH and Chef Server traffic"
  vpc_id      = "${module.vpc.vpc_id_out}"

	#allow SSH connectivity
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow Chef server web UI
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

	#allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.project}_${var.environment}_ChefServer_sg_${module.vpc.vpc_id_out}"
    Owner       = "${var.owner}"
    Environment = "${var.environment}"
    Project     = "${var.project}"
  }
}
