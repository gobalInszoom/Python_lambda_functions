/*variable "project" {
  description="The project's name or code which the resource(s) belong to."
  default="Demo"
}
variable "owner" {
  description="The project owner(s) name or email address."
}
variable "environment" {
  description="The environment name or code which the resource(s) belong to."
}*/
provider "aws" {
    region = "${var.aws_region}"
}
variable "availability_zone" { }
variable "vpc_cidr_block" { default="10.0.0.0/16" }
variable "aws_region" { default="eu-west-1" }

variable "subnet_1_public_cidr_block" { default="10.0.0.0/21" }
variable "subnet_2_public_cidr_block" { default="10.0.8.0/21" }
variable "subnet_3_public_cidr_block" { default="10.0.16.0/21" }
variable "subnet_1_private_cidr_block" { default="10.0.100.0/21" }
variable "subnet_1a_private_cidr_block" { default="10.0.100.0/21" }
variable "subnet_2_private_cidr_block" { default="10.0.108.0/21" }
variable "subnet_2a_private_cidr_block" { default="10.0.100.0/21" }
variable "subnet_3_private_cidr_block" { default="10.0.116.0/21" }
variable "subnet_3a_private_cidr_block" { default="10.0.100.0/21" }

variable "nat_ami_id" {
  default = ""
}

variable "key_name" {
  default = "shipra"
}

variable "subnet_1_az" {
    default = "a"
}
variable "subnet_2_az" {
    default = "b"
}
variable "subnet_3_az" {
    default = "c"
}
variable "db_instance_type" {
  default = ""
}
variable "connection_keyfile_path" {
  default = ""
}
variable "rhel_ami_id" {
  default = ""
}
variable "logs_size" {
  default = ""
}
variable "data_size" {
  default = ""
}



#EC2 container service
variable "repository_name" 		{ }
variable "ecs_instance" 		{
	type="map"
	default = {}
}


variable "bastion_host"			{
	type="map"
	default = {}
}

/*Module to create VPC with 2 public and 2 private subnets.
Public subnets will receive and route all traffic to internet gateway. Private subnets will route all outgoing traffic to a NAT gateway in their Availability Zone (AZ), while they are not reachable from the public internet.
Output values will list VPC id (1x), subnet ids (4x), public routing table id (1x) applicable for additional public subnets, private routing table id (2x, once per AZ) applicable for additional private subnets within the same AZ.
*/

module "vpc"{
    source           = "../Modules/vpc_base"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.vpc_cidr_block}"
}

#create Internet Gateway and a routing table for public subnets
module "igw"{
    source           = "../Modules/internet_gateway"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    vpc_id           = "${module.vpc.vpc_id_out}"
}

#create Security group for NAT instance
module "nat_sg" {
  source = "../Modules/security_groups/nat_gateway"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  vpc_id           = "${module.vpc.vpc_id_out}"
}

module "public_route"{
    source           = "../Modules/routing_table"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    cidr_block       = "0.0.0.0/0"
    gateway_id       = "${module.igw.igw_id_out}"
    aws_region       = "${var.aws_region}"
    purpose          = "public"
}

#create public subnets in two different availability zones

module "subnet_public_a" {
    source           = "../Modules/subnet_public"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_1_public_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_1_az}"
    route_table_id   = "${module.public_route.route_table_id_out}"
}

module "subnet_private_a" {
    source           = "../Modules/subnet_private"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_1_private_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_1_az}"
    nat_ami_id       = "${var.nat_ami_id}"
    key_name         = "${var.key_name}"
    public_subnet_id = "${module.subnet_public_a.subnet_id_out}"
    nat_sg_out       = "${module.nat_sg.nat_sg_out}"
    nat_name         = "a"
}

module "subnet_private_a_1" {
    source           = "../Modules/additional_pvt_subnet"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_1a_private_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_1_az}"
    pvt_route_table_id   = "${module.subnet_private_a.private_routing_table_id}"
}

module "subnet_public_b" {
    source           = "../Modules/subnet_public"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_2_public_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_2_az}"
    route_table_id   = "${module.public_route.route_table_id_out}"
}

module "subnet_private_b" {
    source           = "../Modules/subnet_private"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_2_private_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_2_az}"
    nat_ami_id       = "${var.nat_ami_id}"
    key_name         = "${var.key_name}"
    public_subnet_id = "${module.subnet_public_b.subnet_id_out}"
    nat_sg_out       = "${module.nat_sg.nat_sg_out}"
    nat_name         = "b"
}

module "subnet_private_b_1" {
    source           = "../Modules/additional_pvt_subnet"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_2a_private_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_2_az}"
    pvt_route_table_id   = "${module.subnet_private_b.private_routing_table_id}"
}

module "subnet_public_c" {
    source           = "../Modules/subnet_public"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_3_public_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_3_az}"
    route_table_id   = "${module.public_route.route_table_id_out}"
}


#create private subnets in two different availability zones
module "subnet_private_c" {
    source           = "../Modules/subnet_private"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_3_private_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_3_az}"
    nat_ami_id       = "${var.nat_ami_id}"
    key_name         = "${var.key_name}"
    public_subnet_id = "${module.subnet_public_c.subnet_id_out}"
    nat_sg_out       = "${module.nat_sg.nat_sg_out}"
    nat_name         = "c"
}

module "subnet_private_c_1" {
    source           = "../Modules/additional_pvt_subnet"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.subnet_3a_private_cidr_block}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.subnet_3_az}"
    pvt_route_table_id   = "${module.subnet_private_c.private_routing_table_id}"
}

module "db_setup" {
    source           = "../Modules/db_setup"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    key_name         = "${var.key_name}"
    logs_size        = "${var.logs_size}"
    data_size        = "${var.data_size}"
    vpc_id           = "${module.vpc.vpc_id_out}"
    subnet1_id       = "${module.subnet_private_a.subnet_id_out}"
    subnet2_id       = "${module.subnet_private_b.subnet_id_out}"
    subnet3_id       = "${module.subnet_private_c.subnet_id_out}"
    pub_sub1_id      = "${module.subnet_public_a.subnet_id_out}"
    pub_sub2_id      = "${module.subnet_public_b.subnet_id_out}"
    pub_sub3_id      = "${module.subnet_public_c.subnet_id_out}"
    connection_keyfile_path = "${var.connection_keyfile_path}"
    nat_public_ip_a  = "${module.subnet_private_a.nat_public_ip}"
    nat_public_ip_b  = "${module.subnet_private_b.nat_public_ip}"
    nat_public_ip_c  = "${module.subnet_private_c.nat_public_ip}"
    instance_type    = "${var.db_instance_type}"
    aws_region       = "${var.aws_region}"
    az1              = "${var.subnet_1_az}"
    az2              = "${var.subnet_2_az}"
    az3              = "${var.subnet_3_az}"
}

module "bastion" {
    source              = "../Modules/ecs/bastion/"
    owner               = "${var.owner}"
    project             = "${var.project}"
    environment         = "${var.environment}"
    vpc_id              = "${module.vpc.vpc_id_out}"
    vpc_cidr_block      = "${var.vpc_cidr_block}"
    #public_subnet_ids   = "${module.public_subnet.subnet_ids}"

    public_subnet_ids = "${module.subnet_public_a.subnet_id_out}"
    bastion_host        = "${var.bastion_host}"
}


# Added the ECS section

module "ecs" {
	#source 				= "./../../modules/ecs/"
  source 				= "../Modules/ecs/"

	owner               = "${var.owner}"
	project				= "${var.project}"
	environment         = "${var.environment}"
  vpc_id 				= "${module.vpc.vpc_id_out}"

   #	public_subnet_ids	= "${module.network.public_subnet_ids}"
   #	private_subnet_ids	= "${module.network.private_subnet_ids}"*/
   #private_subnet_ids =["${var.subnet1_id}", "${var.subnet2_id}","${var.subnet3_id}"]
  # 	bastion_private_ip	= "${module.network.bastion_private_ip}"
//assign by Shipra

    public_subnet_ids = "${module.subnet_public_a.subnet_id_out},${module.subnet_public_b.subnet_id_out},${module.subnet_public_c.subnet_id_out}"
    private_subnet_ids = "${module.subnet_private_a.subnet_id_out},${module.subnet_private_b.subnet_id_out},${module.subnet_private_c.subnet_id_out}"
# private_subnet_ids ="${module.subnet_private_a.subnet_id_out}"
# public_subnet_ids="${module.subnet_public_a.subnet_id_out}"


   	repository_name		= "${var.repository_name}"

   	bastion_private_ip	= "${module.bastion.private_ip}"
   	ecs_instance 		= "${var.ecs_instance}"

   	availability_zone   = "${var.availability_zone}"

}
