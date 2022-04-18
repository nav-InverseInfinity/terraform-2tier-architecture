provider "aws" {
  
  region = "eu-west-2"
}



#vpc
resource "aws_vpc" "dev" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "dev"
  }
}


#subnet -for HA create three public and two private subnets


resource "aws_subnet" "public-subnet" {
  count    = length(var.public_subnet_cidr)
  vpc_id     = aws_vpc.dev.id
  cidr_block = element(var.public_subnet_cidr,count.index)
  availability_zone = element(var.AZ,count.index)
  map_public_ip_on_launch = true


  tags = {
    Name = "public-subnet-${count.index +1}"
  }
}

#private subnets for Database 
resource "aws_subnet" "private-subnet" {
  count    = length(var.private_subnet_cidr)
  vpc_id     = aws_vpc.dev.id
  cidr_block = element(var.private_subnet_cidr,count.index)
  availability_zone = element(var.AZ,count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-${count.index +1}"
  }
}

#Inernet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev-igw"
  }

}

#Elastic IP for NAT 
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

#Nat gateway

resource "aws_nat_gateway" "NAT_GW" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public-subnet.*.id, 0) #selecting the first public subnet id
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "dev-NAT-gw"
  }
}

#route table
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GW.id
  }

  tags = {
    Name = "private-rt"
  }
}

#route table subnet association 

resource "aws_route_table_association" "public-subnet-association" {
  count = length(var.public_subnet_cidr)
  subnet_id      = element(aws_subnet.public-subnet.*.id,count.index)
  route_table_id = aws_route_table.public-route.id
}

resource "aws_route_table_association" "private-subnet-association" {
  count = length(var.private_subnet_cidr)
  subnet_id      = element(aws_subnet.private-subnet.*.id, count.index)
  route_table_id = aws_route_table.private-route.id
}
