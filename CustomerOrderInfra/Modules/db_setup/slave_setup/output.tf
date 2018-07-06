output "Slave_Instance_id" {
    value = "${aws_instance.Slave_Instance.id}"
}

output "Slave_Instance_ip" {
    value = "${aws_instance.Slave_Instance.private_ip}"
}
#output "nat_gateway_ip" {
#    value = "${aws_eip.nat_gateway_ip.id}"
#}
