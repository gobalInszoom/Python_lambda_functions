variable "project" { description="The project's name or code which the resource(s) belong to." }
variable "owner" { description="The project owner(s) name or email address." }
variable "environment" { description="The environment name or code which the resource(s) belong to." }

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
