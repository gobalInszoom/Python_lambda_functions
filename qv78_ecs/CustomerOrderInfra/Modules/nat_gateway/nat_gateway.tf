provider "aws" {}

#resource "aws_eip" "nat_gateway_ip" {
#    vpc = true
#}

#resource "aws_nat_gateway" "nat_gateway" {
#    allocation_id = "${aws_eip.nat_gateway_ip.id}"
#    subnet_id     = "${var.subnet_id}"
#}
data "aws_ami" "nat_ami" {
  most_recent = true
  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
  filter {
   name = "virtualization-type"
   values = ["hvm"]
 }
}
resource "aws_instance" "NAT_Instance" {

    ami                    = "${data.aws_ami.nat_ami.id}"
    instance_type          = "t2.medium"
	  count                  = "1"
    key_name               = "${var.key_name}"
    subnet_id              = "${var.public_subnet_id}"
    source_dest_check      = false
    associate_public_ip_address = true
    vpc_security_group_ids = ["${var.nat_sg_out}"]
    tags {
        Name = "Nat_Instance_${var.nat_name}"
        Owner = "${var.owner}"
        Environment = "${var.environment}"
        Project = "${var.project}"
    }
}
