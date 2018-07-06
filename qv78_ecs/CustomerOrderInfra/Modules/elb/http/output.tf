output "http_elb_id" {
    value = "${aws_elb.http_elb.id}"
}

output "http_elb_ip" {
    value = "${aws_elb.http_elb.dns_name}"
}
