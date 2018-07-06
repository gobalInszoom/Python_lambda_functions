#create a private subnet in an availability zone with NAT gateway and routing table associated
#output private subnet id and private routing table id applicable for additional private subnet within the same Availability zone

#create NAT gateway
module "nat_gateway" {
    source           = "./../nat_gateway"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    nat_ami_id       = "${var.nat_ami_id}"
    key_name         = "${var.key_name}"
    public_subnet_id = "${var.public_subnet_id}"
    nat_sg_out       = "${var.nat_sg_out}"
    nat_name         = "${var.nat_name}"
}

module "subnet_private" {
    source           = "./../subnet"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    cidr_block       = "${var.cidr_block}"
    vpc_id           = "${var.vpc_id}"
    aws_region       = "${var.aws_region}"
    availability_zone= "${var.availability_zone}"
    purpose          = "private"
    map_public_ip_on_launch = "false"
}

#create a temporary association with public route table
#resource "aws_route_table_association" "priv_subnet_pub_rt_association" {
#    subnet_id = "${module.subnet_private.subnet_id_out}"
#    route_table_id = "${var.public_rt_id}"
#}



#create routing table and associate with subnet
module "private_route_table"{
    source           = "./../pvt_routing_table"
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    vpc_id           = "${var.vpc_id}"
    cidr_block       = "0.0.0.0/0"
    gateway_id       = "${module.nat_gateway.nat_gateway_id}"
    aws_region       = "${var.aws_region}"
    purpose          = "private"
}

resource "aws_route_table_association" "private_subnet_route_association" {
    subnet_id = "${module.subnet_private.subnet_id_out}"
    route_table_id = "${module.private_route_table.route_table_id_out}"
}

###################################################################
###################       NEXUS     ###############################
###################################################################
#create Security group for nexus instance
module "nexus_sg" {
  source           = "./../security_groups/nexus_sg"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  vpc_id           = "${var.vpc_id}"
}

module "nexus" {
  source           = "./../management_tools/nexus"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  rhel_ami_id      = "${var.rhel_ami_id}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${module.subnet_private.subnet_id_out}"
  nexus_sg_out      = "${module.nexus_sg.nexus_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${module.nat_gateway.nat_public_ip}"
  aws_region       = "${var.aws_region}"
}

module "nexus_elb" {
    source           = "./../elb/http"
    elb_name         = "Nexus"
    port             = 8081
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    subnet1_id       = "${var.subnet1_id}"
    subnet2_id       = "${var.subnet2_id}"
    instance_id      = "${module.nexus.Nexus_id}"
    jenkins_sg_out   = "${module.nexus_sg.nexus_sg_out}"
}

###################################################################
###################       JENKINS    ##############################
###################################################################
#create Security group for jenkins instance
module "js_sg" {
  source           = "./../security_groups/js_sg"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  vpc_id           = "${var.vpc_id}"
}

resource "aws_efs_mount_target" "jenkins_efs" {
  file_system_id = "${var.efs_id}"
  subnet_id = "${module.subnet_private.subnet_id_out}"
  security_groups = ["${module.js_sg.js_sg_out}"]
}

module "jenkins" {
  source           = "./../management_tools/jenkins"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  rhel_ami_id      = "${var.rhel_ami_id}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${module.subnet_private.subnet_id_out}"
  jenkins_sg_out   = "${module.js_sg.js_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${module.nat_gateway.nat_public_ip}"
  aws_region       = "${var.aws_region}"
  file_system_id   = "${var.efs_id}"
}

module "jenkins_elb" {
    source           = "./../elb/http"
    elb_name         = "Jenkins"
    port             = 8080
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    subnet1_id       = "${var.subnet1_id}"
    subnet2_id       = "${var.subnet2_id}"
    instance_id      = "${module.jenkins.Jenkins_id}"
    jenkins_sg_out   = "${module.js_sg.js_sg_out}"
}

###################################################################
###################       CHEF    #################################
###################################################################
#create Security group for CHEF instance
module "chef_sg" {
  source           = "./../security_groups/chef_sg"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  vpc_id           = "${var.vpc_id}"
}


#module "chef" {
#  source           = "./../management_tools/chef"
#  owner            = "${var.owner}"
#  project          = "${var.project}"
#  environment      = "${var.environment}"
#  rhel_ami_id      = "${var.rhel_ami_id}"
#  key_name         = "${var.key_name}"
#  private_subnet_id= "${module.subnet_private.subnet_id_out}"
#  chef_sg_out      = "${module.chef_sg.chef_sg_out}"
#  connection_keyfile_path = "${var.connection_keyfile_path}"
#  nat_public_ip    = "${module.nat_gateway.nat_public_ip}"
#  aws_region       = "${var.aws_region}"
#}

#module "chef_elb" {
#    source           = "./../elb/https"
#    port             = 443
#    owner            = "${var.owner}"
#    environment      = "${var.environment}"
#    project          = "${var.project}"
#    subnet1_id       = "${var.subnet1_id}"
#    subnet2_id       = "${var.subnet2_id}"
#    instance_id      = "${module.chef.Chef_id}"
#    jenkins_sg_out   = "${module.chef_sg.chef_sg_out}"
#    connection_keyfile_path = "${var.connection_keyfile_path}"
#}

module "sonar_sg" {
  source           = "./../security_groups/sonar_sg"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  vpc_id           = "${var.vpc_id}"
}

module "sonar" {
  source           = "./../management_tools/sonar"
  owner            = "${var.owner}"
  project          = "${var.project}"
  environment      = "${var.environment}"
  rhel_ami_id      = "${var.rhel_ami_id}"
  key_name         = "${var.key_name}"
  private_subnet_id= "${module.subnet_private.subnet_id_out}"
  sonar_sg_out      = "${module.sonar_sg.sonar_sg_out}"
  connection_keyfile_path = "${var.connection_keyfile_path}"
  nat_public_ip    = "${module.nat_gateway.nat_public_ip}"
  aws_region       = "${var.aws_region}"
}

module "sonar_elb" {
    source           = "./../elb/http"
    elb_name         = "sonar"
    port             = 9000
    owner            = "${var.owner}"
    project          = "${var.project}"
    environment      = "${var.environment}"
    subnet1_id       = "${var.subnet1_id}"
    subnet2_id       = "${var.subnet2_id}"
    instance_id      = "${module.sonar.Sonar_id}"
    jenkins_sg_out   = "${module.sonar_sg.sonar_sg_out}"
}
