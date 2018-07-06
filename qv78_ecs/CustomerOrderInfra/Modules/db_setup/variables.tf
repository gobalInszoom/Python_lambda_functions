variable "project" { description="The project's name or code which the resource(s) belong to." }
variable "owner" { description="The project owner(s) name or email address." }
variable "environment" { description="The environment name or code which the resource(s) belong to." }

variable "key_name" {
  default = ""
}
variable "rhel_ami_id" {
  default = ""
}
variable "vpc_id" {
  default = ""
}
variable "connection_keyfile_path" {
  default = ""
}
variable "subnet1_id" {
  default = ""
}
variable "subnet2_id" {
  default = ""
}
variable "subnet3_id" {
  default = ""
}
variable "nat_public_ip_a" {
  default = ""
}
variable "nat_public_ip_b" {
  default = ""
}
variable "nat_public_ip_c" {
  default = ""
}
variable "instance_type" {
  default = ""
}
variable "aws_region" {
  default = ""
}
variable "az1" {
  default = ""
}
variable "az2" {
  default = ""
}
variable "az3" {
  default = ""
}
variable "pub_sub1_id" {
  default = ""
}
variable "pub_sub2_id" {
  default = ""
}
variable "pub_sub3_id" {
  default = ""
}
variable "logs_size" {
  default = ""
}
variable "data_size" {
  default = ""
}
