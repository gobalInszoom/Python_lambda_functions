variable "project" { description="The project's name or code which the resource(s) belong to." }
variable "owner" { description="The project owner(s) name or email address." }
variable "environment" { description="The environment name or code which the resource(s) belong to." }

variable "key_name" {
  default = ""
}
variable "rhel_ami_id" {
  default = ""
}
variable "jenkins_sg_out" {
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
variable "js_elb_id" {
  default = ""
}
variable "file_system_id" {
  default = ""
}
