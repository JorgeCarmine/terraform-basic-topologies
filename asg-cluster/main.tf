provider "aws" {
  region     = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "web_ec2_sg" {
  name = "web-ec2-sg"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "ec2" {
  image_id = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_ec2_sg.id]

  user_data                   = <<-EOF
              #!/bin/bash
              ip_address=$(hostname -I | awk '{print $1}')
              echo "Hello word: $ip_address" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cluster_ag" {
  launch_configuration = aws_launch_configuration.ec2.name
  vpc_zone_identifier = data.aws_subnets.default.ids

  # LB configuration
  target_group_arns = [aws_lb_target_group.cluster_asg.id]
  health_check_type = "ELB" # default EC2

  min_size = 2
  max_size = 5
  tag {
    key = "Name"
    value = "terraform-instance"
    propagate_at_launch = true
  }
}

# Load balancer

resource "aws_security_group" "alb_sg" {
  name = "Web app load balancer security group"
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "cluster_lb" {
  name = "web-app-load-balancer"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.cluster_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_target_group" "cluster_asg" {
  name = "single-server-asg"
  port = var.server_port
  protocol = "HTTP"

  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = 200
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_alb_listener_rule" "lb_listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.cluster_asg.arn
  }
}
