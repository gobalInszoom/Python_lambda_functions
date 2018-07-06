# Enter the region
aws_region="us-east-1"

# please uncomment and enter email address e.g. owner = "user@example.com"
owner = "vinay.wadagavi@in.tesco.com"

environment="Management"
project ="CustomerOrder"

vpc_cidr_block = "10.0.0.0/16"
subnet_1_public_cidr_block = "10.0.0.0/21"
subnet_2_public_cidr_block = "10.0.8.0/21"
subnet_3_public_cidr_block = "10.0.16.0/21"
subnet_1_private_cidr_block = "10.0.100.0/21"
subnet_2_private_cidr_block = "10.0.108.0/21"
subnet_3_private_cidr_block = "10.0.116.0/21"

#Nat instance ami
nat_ami_id="ami-184dc970"
key_name="vinay-Nvirginia"

#RHEL ami id
rhel_ami_id="ami-b63769a1"

#Entire the pem file full path
connection_keyfile_path="D:/vinay-Nvirginia.pem"
