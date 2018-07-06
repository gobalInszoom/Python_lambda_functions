# Enter the region
aws_region="eu-west-1"

# please uncomment and enter email address e.g. owner = "user@example.com"
owner = "vinay.wadagavi@in.tesco.com"

environment="dev"
project ="CustomerOrder"

vpc_cidr_block = "10.0.0.0/16"
subnet_1_public_cidr_block = "10.0.0.0/21"
subnet_2_public_cidr_block = "10.0.8.0/21"
subnet_3_public_cidr_block = "10.0.16.0/21"
subnet_1_private_cidr_block = "10.0.100.0/21"
subnet_1a_private_cidr_block = "10.0.108.0/21"
subnet_2_private_cidr_block = "10.0.116.0/21"
subnet_2a_private_cidr_block = "10.0.124.0/21"
subnet_3_private_cidr_block = "10.0.132.0/21"
subnet_3a_private_cidr_block = "10.0.140.0/21"

#Key Details
key_name="shipra"
connection_keyfile_path="D:/key/shipra.pem"
//private_key = "${file("~/.ssh/lx-eu-west-1.pem")}"

#DB configurations
db_instance_type="t2.xlarge"
logs_size="40"  #Size is in GB ex:logs_size="40"
data_size="40"  #Size is in GB ex:data_size="40"

#bastion				= {  , ,  } # specify according to region
bastion_host 	= {
 ami 			= "ami-02ace471"
 instance_type	= "t2.micro"
 key_name		= "shipra"
}


# ECS
ecs_instance 	= {
 ami 			= "ami-a7f2acc1"  // TODO : write search query to get ami id
 instance_type	= "t2.micro"
 key_name		= "shipra"
 min			= 3
 max			= 6
 desired		= 3
}

repository_name		= "customer" // ECR Rigistery name
availability_zone = "eu-west-1a,eu-west-1b,eu-west-1c"
