output "sonar_sg_out" {
    value = "${aws_security_group.sonar_sg.id}"
}
