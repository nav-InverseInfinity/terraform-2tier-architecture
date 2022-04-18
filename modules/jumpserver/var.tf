variable "instance-AZ" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

}
variable "instance-type" {

  default = "t2.micro"
}

variable "subnet_id" {} #public subnet


variable "dev_vpc" {}           #call from vpc module
