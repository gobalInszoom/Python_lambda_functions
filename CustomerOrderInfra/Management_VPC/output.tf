output "vpc_id_out" {
    value = "${module.vpc.vpc_id_out}"
}

output "nat_sg_out" {
  value = "${module.nat_sg.nat_sg_out}"
}

output "subnet_public_1_id_out" {
    value = "${module.subnet_public_a.subnet_id_out}"
}

output "subnet_public_2_id_out" {
    value = "${module.subnet_public_b.subnet_id_out}"
}

output "subnet_public_3_id_out" {
    value = "${module.subnet_public_b.subnet_id_out}"
}

output "public_routing_table_id_out" {
    value = "${module.public_route.route_table_id_out}"
}

output "subnet_private_1_id_out" {
    value = "${module.subnet_private_a.subnet_id_out}"
}

output "subnet_private_2_id_out" {
    value = "${module.subnet_private_b.subnet_id_out}"
}

output "subnet_private_3_id_out" {
    value = "${module.subnet_private_b.subnet_id_out}"
}

output "private_routing_table_1_id_out" {
    value = "${module.subnet_private_a.private_routing_table_id}"
}

output "private_routing_table_2_id_out" {
    value = "${module.subnet_private_b.private_routing_table_id}"
}

output "private_routing_table_3_id_out" {
    value = "${module.subnet_private_c.private_routing_table_id}"
}

#output "chef_server_sg_id" {
#    value = "${aws_security_group.chef-server-sg.id}"
#}
