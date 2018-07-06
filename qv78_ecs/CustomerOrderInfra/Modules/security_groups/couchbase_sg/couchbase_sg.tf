resource "aws_security_group" "couchbase_sg" {
  name        = "${var.project}_${var.environment}_couchbase_sg"
  description = "Allow SSH HTTP and HTTPS traffic and port 8081"
  vpc_id      = "${var.vpc_id}"

	#allow SSH connectivity
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow HTTPS connectivity
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow HTTP connectivity
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow HTTP connectivity
  ingress {
    from_port   = 8091
    to_port     = 8093
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow erlang connectivity
  ingress {
    from_port   = 4369
    to_port     = 4369
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9105
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9998
    to_port     = 9999
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 11207
    to_port     = 11215
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 18091
    to_port     = 18093
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 21100
    to_port     = 21299
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

	#allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
      Name = "${var.project}_${var.environment}_couchbase_Security_Group"
      Owner = "${var.owner}"
      Environment = "${var.environment}"
      Project = "${var.project}"
  }
}
