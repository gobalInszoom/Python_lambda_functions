output "nat_gateway_id" {
    value = "${aws_instance.NAT_Instance.id}"
}

output "nat_public_ip"{
  value = "${aws_instance.NAT_Instance.public_ip}"
}

#output "nat_gateway_ip" {
#    value = "${aws_eip.nat_gateway_ip.id}"
#}
