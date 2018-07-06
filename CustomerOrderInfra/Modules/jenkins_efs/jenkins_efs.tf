resource "aws_efs_file_system" "jenkins_efs" {
  creation_token = "jenkins_efs"
  tags {
    Name = "${var.project}_${var.environment}_EFS"
    Owner = "${var.owner}"
    Environment = "${var.environment}"
    Project = "${var.project}"
  }
}
