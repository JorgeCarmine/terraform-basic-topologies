provider "aws" {
  region     = "us-east-1"
}

resource "aws_instance" "carmine_ec2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data                   = <<-EOF
              #!/bin/bash
              echo "Hello word" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "carmine_ec2_sg" {
  name = "carmine-ec2-sg"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
