output "Master_Instance_id" {
    value = "${aws_instance.Master_Instance.id}"
}

#output "nat_gateway_ip" {
#    value = "${aws_eip.nat_gateway_ip.id}"
#}
