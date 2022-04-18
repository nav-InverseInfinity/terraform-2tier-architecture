
provider "aws" {
  region = "eu-west-2"
}

module "dev-vpc" {

  source = "./modules/vpc"

}

module "jumpserver" {

  source = "./modules/jumpserver"
  
  dev_vpc = module.dev-vpc.dev_vpc_id
  subnet_id = module.dev-vpc.public_subnet_id[0]
  
}

module "dev-ASG" {
  
  source = "./modules/ASG"

  dev_vpc = module.dev-vpc.dev_vpc_id
  jumpserver-sg = module.jumpserver.jumpserver_sg
  asg_max_size = 2
  asg_min_size = 1
  desired_capacity = 1
  dev_private_subnet = module.dev-vpc.private_subnet_id 
  dev_public_subnet =  module.dev-vpc.public_subnet_id

}
