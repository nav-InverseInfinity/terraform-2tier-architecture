output "jumpserver_sg" {
  value = [aws_security_group.jumpserver-sg.id]
}

