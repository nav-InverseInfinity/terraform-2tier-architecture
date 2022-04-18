provider "aws" {

  region = "eu-west-2"
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
resource "aws_key_pair" "key_pair" {
  key_name   = "JS-instance-key"
  public_key = file("~/test_terraform/modules/jumpserver/terraform-key.pub")
}

resource "aws_instance" "jumpserver-instances" {
  
  ami               = data.aws_ami.amazon-linux-2.id
  instance_type     = var.instance-type
  key_name          = aws_key_pair.key_pair.key_name
  availability_zone = var.instance-AZ[0]
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.jumpserver-sg.id]
    

  tags = {
    Name = "JumpServer"
    Env  = "dev"
  }
}

resource "aws_security_group" "jumpserver-sg" {
  name        = "jumpserver-sg"
  description = "Allow web inbound traffic"
  vpc_id      = var.dev_vpc 

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "jumpserver-sg"
  }
}



