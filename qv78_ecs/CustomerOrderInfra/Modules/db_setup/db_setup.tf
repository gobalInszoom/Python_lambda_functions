###################################################################
###################       couchbase     ###############################
###################################################################

data "aws_ami" "rhel_ami" {
  most_recent = true
  filter {
    name = "name"
    values = ["RHEL-7.?_HVM_GA*"]
  }
  filter {
   name = "virtualization-type"
   values = ["hvm"]
 }
}

#create Security group for couchbase instance
module "couchbase_sg" {
  source           = "./../security_groups/couchbase_sg"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  vpc_id           = "${var.vpc_id}"
}

module "a1" {
  source           = "./slave_setup"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${var.subnet1_id}"
  instance_type    = "${var.instance_type}"
  couchbase_sg_out = "${module.couchbase_sg.couchbase_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${var.nat_public_ip_a}"
  aws_region       = "${var.aws_region}"
  az               = "${var.az1}"
  logs_size        = "${var.logs_size}"
  data_size        = "${var.data_size}"
  rhel_ami_id      = "${data.aws_ami.rhel_ami.id}"
}

module "b1" {
  source           = "./slave_setup"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${var.subnet2_id}"
  instance_type    = "${var.instance_type}"
  couchbase_sg_out = "${module.couchbase_sg.couchbase_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${var.nat_public_ip_a}"
  aws_region       = "${var.aws_region}"
  az               = "${var.az2}"
  logs_size        = "${var.logs_size}"
  data_size        = "${var.data_size}"
  rhel_ami_id      = "${data.aws_ami.rhel_ami.id}"
}

module "b2" {
  source           = "./slave_setup"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${var.subnet2_id}"
  instance_type    = "${var.instance_type}"
  couchbase_sg_out = "${module.couchbase_sg.couchbase_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${var.nat_public_ip_a}"
  aws_region       = "${var.aws_region}"
  az               = "${var.az2}"
  logs_size        = "${var.logs_size}"
  data_size        = "${var.data_size}"
  rhel_ami_id      = "${data.aws_ami.rhel_ami.id}"
}

module "c1" {
  source           = "./slave_setup"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${var.subnet3_id}"
  instance_type    = "${var.instance_type}"
  couchbase_sg_out = "${module.couchbase_sg.couchbase_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${var.nat_public_ip_a}"
  aws_region       = "${var.aws_region}"
  az               = "${var.az3}"
  logs_size        = "${var.logs_size}"
  data_size        = "${var.data_size}"
  rhel_ami_id      = "${data.aws_ami.rhel_ami.id}"
}
module "c2" {
  source           = "./slave_setup"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${var.subnet3_id}"
  instance_type    = "${var.instance_type}"
  couchbase_sg_out = "${module.couchbase_sg.couchbase_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${var.nat_public_ip_a}"
  aws_region       = "${var.aws_region}"
  az               = "${var.az3}"
  logs_size        = "${var.logs_size}"
  data_size        = "${var.data_size}"
  rhel_ami_id      = "${data.aws_ami.rhel_ami.id}"
}

module "couchbase_master" {
  source           = "./master_setup"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${var.subnet1_id}"
  instance_type    = "${var.instance_type}"
  couchbase_sg_out = "${module.couchbase_sg.couchbase_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${var.nat_public_ip_a}"
  aws_region       = "${var.aws_region}"
  az1              = "${var.az1}"
  az2              = "${var.az2}"
  az3              = "${var.az3}"
  logs_size        = "${var.logs_size}"
  data_size        = "${var.data_size}"
  slave1_ip        = "${module.a1.Slave_Instance_ip}"
  slave2_ip        = "${module.b1.Slave_Instance_ip}"
  slave3_ip        = "${module.b2.Slave_Instance_ip}"
  slave4_ip        = "${module.c1.Slave_Instance_ip}"
  slave5_ip        = "${module.c2.Slave_Instance_ip}"
  rhel_ami_id      = "${data.aws_ami.rhel_ami.id}"
}

module "couchbase_elb" {
    source           = "./../elb/http"
    elb_name         = "couchbase"
    port             = 8091
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    subnet1_id       = "${var.pub_sub1_id}"
    subnet2_id       = "${var.pub_sub2_id}"
    instance_id      = "${module.couchbase_master.Master_Instance_id}"
    jenkins_sg_out   = "${module.couchbase_sg.couchbase_sg_out}"
}
