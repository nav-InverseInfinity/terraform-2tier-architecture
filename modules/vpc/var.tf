#vpc cidr
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

#public-subnet 
variable "public_subnet_cidr" {
  
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
# AZs
variable "AZ" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

}

#private-subnet 
variable "private_subnet_cidr" {
  
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}
