output "couchbase_sg_out" {
    value = "${aws_security_group.couchbase_sg.id}"
}
