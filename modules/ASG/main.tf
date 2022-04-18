
provider "aws" {

  region = "eu-west-2"
}
#we need AMI image data for instances

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

#Key pair for instances

resource "aws_key_pair" "key_pair" {
  key_name   = "app-instance-key"
  public_key = file("~/test_terraform/modules/ASG/terraform-key.pub")
}



resource "aws_launch_configuration" "ASG_launch" {
  name                        = "asg-web-server"
  image_id                    = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key_pair.key_name
  security_groups             = [aws_security_group.ASG-sg.id]
  user_data                   = file("~/test_terraform/modules/ASG/install_apache.sh")
  associate_public_ip_address = false
}



#Autoscaling group
resource "aws_autoscaling_group" "dev-asg" {
  name                      = "dev_asg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = var.desired_capacity
  launch_configuration      = aws_launch_configuration.ASG_launch.name
  vpc_zone_identifier       = var.dev_private_subnet

  tag {
    key                 = "Name"
    value               = "asg-instances"
    propagate_at_launch = true
  }
}

#Auto scaling policy up
resource "aws_autoscaling_policy" "asg-scale-up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.dev-asg.name
  policy_type            = "SimpleScaling"
}

#Cloud Watch metric to scale up

resource "aws_cloudwatch_metric_alarm" "scale-up-alarm" {
  alarm_name          = "asg-scale-up-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.dev-asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.asg-scale-up.arn]
}


#Auto scaling policy down
resource "aws_autoscaling_policy" "asg-scale-down" {
  name                   = "scale-down"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.dev-asg.name
  policy_type            = "SimpleScaling"
}

#Cloud Watch metric to scale down
resource "aws_cloudwatch_metric_alarm" "scale-down-alarm" {
  alarm_name          = "asg-scale-down-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.dev-asg.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.asg-scale-down.arn]
}

#Attaching target group to ASG
resource "aws_autoscaling_attachment" "asg_target_group" {
  autoscaling_group_name = aws_autoscaling_group.dev-asg.id
  lb_target_group_arn    = aws_lb_target_group.alb-target-group.arn
}

resource "aws_security_group" "ASG-sg" {
  name        = "ASG-sg"
  description = "Allow web inbound traffic"
  vpc_id      = var.dev_vpc 

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = var.jumpserver-sg
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ASG-sg"
  }
}


##################################
### Application Load Balancer ####
##################################

resource "aws_lb" "app-alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.ALB-sg.id]
  subnets            = var.dev_public_subnet

  tags = {
    Name = "ALB"
  }
}


# ALB listeners
resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.app-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }
}

#target group
resource "aws_lb_target_group" "alb-target-group" {
  name        = "dev-alb"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.dev_vpc

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/"
  }

}

resource "aws_security_group" "ALB-sg" {
  name        = "ALB-sg"
  description = "Allow web inbound traffic"
  vpc_id      = var.dev_vpc 

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
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
    Name = "ALB-sg"
  }
}

