output "chef_sg_out" {
    value = "${aws_security_group.chef_sg.id}"
}
