resource "tls_private_key" "private_key" {
    algorithm = "ECDSA"
    ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "signed_ca_cert" {
    key_algorithm = "ECDSA"
    private_key_pem  = "${tls_private_key.private_key.private_key_pem}"

    subject {
        common_name = "${var.project}${var.elb_name}.com"
        organization = "TESCO Bengaluru, Inc"
    }

    validity_period_hours = 17520

    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth",
    ]
}

resource "aws_iam_server_certificate" "ssl_certificate" {
  name = "${var.elb_name}ELB_certificate"
  certificate_body = "${tls_self_signed_cert.signed_ca_cert.cert_pem}"
  private_key = "${tls_private_key.private_key.private_key_pem}"
}

resource "aws_elb" "https_elb" {
  name ="${var.elb_name}ELB"
  subnets = ["${var.subnet1_id}", "${var.subnet2_id}"]
  security_groups = ["${var.jenkins_sg_out}"]

  listener {
    instance_port = "${var.port}"
    instance_protocol = "https"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.ssl_certificate.arn}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:${var.port}"
    interval = 10
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  instances = ["${var.instance_id}"]
  tags {
    Owner = "${var.owner}"
    Environment = "${var.environment}"
    Project = "${var.project}"
  }
}
