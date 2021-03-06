resource "aws_security_group" "sonar_sg" {
  name        = "${var.project}_${var.environment}_Sonar_sg"
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
    from_port   = 9000
    to_port     = 9000
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
      Name = "${var.project}_${var.environment}_Sonar_Security_Group"
      Owner = "${var.owner}"
      Environment = "${var.environment}"
      Project = "${var.project}"
  }
}
