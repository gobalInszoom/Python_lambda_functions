variable "project" { description="The project's name or code which the resource(s) belong to." }
variable "owner" { description="The project owner(s) name or email address." }
variable "environment" { description="The environment name or code which the resource(s) belong to." }

variable "key_name" {
  default = ""
}
variable "rhel_ami_id" {
  default = ""
}
variable "nexus_sg_out" {
  default = ""
}
variable "private_subnet_id" {
  default = ""
}
variable "connection_keyfile_path" {
  default = ""
}
variable "nat_public_ip" {
  default = ""
}
variable "aws_region" {
  default = ""
}
variable "az" {
  default = ""
}
variable "couchbase_sg_out" {
  default = ""
}
variable "instance_type" {
  default = ""
}
variable "logs_size" {
  default = ""
}
variable "data_size" {
  default = ""
}
