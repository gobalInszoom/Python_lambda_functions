provider "aws" {}

#resource "aws_eip" "nat_gateway_ip" {
#    vpc = true
#}

#resource "aws_nat_gateway" "nat_gateway" {
#    allocation_id = "${aws_eip.nat_gateway_ip.id}"
#    subnet_id     = "${var.subnet_id}"
#}
resource "aws_instance" "Slave_Instance" {

    ami                    = "${var.rhel_ami_id}"
    instance_type          = "t2.xlarge"
	  count                  = "1"
    key_name               = "shipra"
    //private_key = "${file("D:/key/shipra.pem")}"
    subnet_id              = "${var.private_subnet_id}"
    source_dest_check      = false
    associate_public_ip_address = true
    vpc_security_group_ids = ["${var.couchbase_sg_out}"]
    user_data              = "${file("../Scripts/couchbase_scripts/slave_setup.sh")}"
    tags {
        Name = "couchbase"
        Owner = "${var.owner}"
        Environment = "${var.environment}"
        Project = "${var.project}"
    }

}

resource "aws_ebs_volume" "data" {
    availability_zone = "${var.aws_region}${var.az}"
    size              = 40
    encrypted         = true
    type              = "gp2"
    tags {
        Name = "Data"
    }
}

resource "aws_ebs_volume" "logs" {
    availability_zone = "${var.aws_region}${var.az}"
    size = 40
    encrypted         = true
    type              = "gp2"
    tags {
        Name = "Logs"
    }
}



resource "aws_volume_attachment" "ebs_data" {
  device_name = "/dev/xvdb"
  volume_id   = "${aws_ebs_volume.data.id}"
  instance_id = "${aws_instance.Slave_Instance.id}"
}

resource "aws_volume_attachment" "ebs_logs" {
  device_name = "/dev/xvdc"
  volume_id   = "${aws_ebs_volume.logs.id}"
  instance_id = "${aws_instance.Slave_Instance.id}"
}

/*
connection {
 type         = "ssh"
 bastion_host = "${var.nat_public_ip}"
 bastion_user = "ec2-user"
 bastion_private_key = "${var.connection_keyfile_path}"

 user     = "ec2-user"
 host     = "${aws_instance.Slave_Instance.private_ip}"
 key_file = "${var.connection_keyfile_path}"
 timeout  = "15m"
}

provisioner "file" {
    source = "../Scripts/couchbase_scripts"
    destination = "/tmp"
}

provisioner "remote-exec" {
    inline = [
      "sudo lsblk",
      "cd /tmp/couchbase_scripts",
      "mv slave_setup.sh install.sh",
      "sudo yum install dos2unix -y",
      "sudo dos2unix install.sh",
      "sudo chmod +x install.sh",
      "sudo sh install.sh"
   ]
}
*/
