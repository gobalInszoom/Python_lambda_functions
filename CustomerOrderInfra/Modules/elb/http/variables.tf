variable "subnet1_id" {
  default = ""
}
variable "subnet2_id" {
  default = ""
}
variable "subnet3_id" {
  default = ""
}
variable "project" { description="The project's name or code which the resource(s) belong to." }
variable "owner" { description="The project owner(s) name or email address." }
variable "environment" { description="The environment name or code which the resource(s) belong to." }
variable "elb_name" {
  default = ""
}
variable "port" {
  default = ""
}
variable "instance_id" {
  default = ""
}
variable "jenkins_sg_out" {
  default = ""
}
