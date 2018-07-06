provider "aws" {}

resource "aws_instance" "Sonar_Instance" {

    ami                    = "${var.rhel_ami_id}"
    instance_type          = "t2.medium"
	  count                  = "1"
    key_name               = "${var.key_name}"
    subnet_id              = "${var.private_subnet_id}"
    source_dest_check      = false
    associate_public_ip_address = true
    vpc_security_group_ids = ["${var.sonar_sg_out}"]

    connection {
     type         = "ssh"
     bastion_host = "${var.nat_public_ip}"
     bastion_user = "ec2-user"
     bastion_private_key = "${var.connection_keyfile_path}"

     user     = "ec2-user"
     host     = "${self.private_ip}"
     key_file = "${var.connection_keyfile_path}"
     timeout  = "15m"
    }

    provisioner "file" {
        source = "../Scripts/sonar_scripts"
        destination = "/tmp"
    }

    tags {
        Name = "Sonar"
        Owner = "${var.owner}"
        Environment = "${var.environment}"
        Project = "${var.project}"
    }

    provisioner "remote-exec" {
    inline = [
      "sudo hostname ${self.public_ip}",
      "cd /tmp/sonar_scripts",
      "mv sonar_install.sh install.sh",
      "sudo yum install dos2unix -y",
      "sudo dos2unix install.sh",
      "sudo chmod +x install.sh",
      "sudo sh install.sh"
   ]
  }
}
