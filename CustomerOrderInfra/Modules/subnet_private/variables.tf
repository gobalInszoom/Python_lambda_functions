variable "project" { description="The project's name or code which the resource(s) belong to." }
variable "owner" { description="The project owner(s) name or email address." }
variable "environment" { description="The environment name or code which the resource(s) belong to." }

variable "vpc_id" {}
variable "cidr_block" {}
variable "availability_zone" {}
variable "aws_region" {}

variable "key_name" {
  default = ""
}
variable "nat_ami_id" {
  default = ""
}
variable "nat_sg_out" {
  default = ""
}
variable "public_subnet_id" {
  default = ""
}
variable "nat_name" {
  default = ""
}
