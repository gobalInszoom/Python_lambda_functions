resource "aws_subnet" "subnet" {
    cidr_block = "${var.cidr_block}"
    vpc_id = "${var.vpc_id}"
    map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
    availability_zone ="${var.aws_region}${var.availability_zone}"
    tags {
        Name = "${var.project}_${var.environment}_${var.aws_region}${var.availability_zone}_${var.purpose}_subnet"
        Owner = "${var.owner}"
        Environment = "${var.environment}"
        Project = "${var.project}"
        Purpose = "${var.purpose}"
    }
}
