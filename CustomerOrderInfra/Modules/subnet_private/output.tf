output "subnet_id_out" {
    value = "${module.subnet_private.subnet_id_out}"
}

output "private_routing_table_id" {
    value = "${module.private_route_table.route_table_id_out}"
}

output "nat_public_ip" {
  value = "${module.nat_gateway.nat_public_ip}"
}
