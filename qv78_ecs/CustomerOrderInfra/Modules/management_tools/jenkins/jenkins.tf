provider "aws" {}


resource "aws_instance" "Jenkins_Instance" {

    ami                    = "${var.rhel_ami_id}"
    instance_type          = "t2.medium"
	  count                  = "1"
    key_name               = "${var.key_name}"
    subnet_id              = "${var.private_subnet_id}"
    source_dest_check      = false
    associate_public_ip_address = true
    vpc_security_group_ids = ["${var.jenkins_sg_out}"]

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
        source = "../Scripts/jenkins_scripts"
        destination = "/tmp"
    }

    provisioner "file" {
        source = "../Scripts/def_plugin"
        destination = "/tmp"
    }

    tags {
        Name = "Jenkins"
        Owner = "${var.owner}"
        Environment = "${var.environment}"
        Project = "${var.project}"
    }

    provisioner "remote-exec" {
    inline = [
      "sudo hostname ${self.public_ip}",
      "sudo yum install nfs-utils -y",
      "sudo mkdir /efs",
      "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${var.file_system_id}.efs.${var.aws_region}.amazonaws.com:/ /efs",
      "cd /tmp/jenkins_scripts",
      "sudo yum install git -y",
      "sudo mv Jenkins_Base_Install.sh /root/install.sh",
      "sudo yum install dos2unix -y",
      "sudo dos2unix /root/install.sh",
      "sudo chmod +x /root/install.sh",
      "sudo sh /root/install.sh"
   ]
  }
}
