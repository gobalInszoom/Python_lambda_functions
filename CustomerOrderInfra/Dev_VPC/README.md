This Terraform is responsible for AWS networking stack creation with proper resource tagging on all created AWS resources.   

The networking stack will consist of an AWS VPC with 2 public subnets (all incoming and outgoing traffic going through an Internet Gateway), and 2 private subnets (all outgoing  traffic going through a NAT Gateway, no incoming traffic) spreaded in two availability zones.

Default values for Management networking stack:

VPC CIDR block: "10.0.0.0/16"  
AWS region: "eu-west-1"  
Public subnet 1 CIDR block: "10.0.0.0/21"  
Public subnet 2 CIDR block: "10.0.8.0/21"  
Private subnet 1 CIDR block: "10.0.100.0/21"  
Private subnet 2 CIDR block: "10.0.108.0/21"  
Availability zone 1: "a"  
Availability zone 2: "b"  

Set dev_vpc_id, qa_vpc_id, preprod_vpc_id, prod_vpc_id accordingly to create VPC peering connections to the other VPCs.
