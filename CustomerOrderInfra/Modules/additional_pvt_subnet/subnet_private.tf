#create a private subnet in an availability zone with NAT gateway and routing table associated
#output private subnet id and private routing table id applicable for additional private subnet within the same Availability zone

module "additional_pvt_subnet" {
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

resource "aws_route_table_association" "private_subnet_route_association" {
    subnet_id = "${module.additional_pvt_subnet.subnet_id_out}"
    route_table_id = "${var.pvt_route_table_id}"
}
