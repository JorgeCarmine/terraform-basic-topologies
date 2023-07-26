variable "region" {
  type = string
  default = "us-east-1"
}

variable "server_port" {
  description = "Default port for EC2 instances"
  type        = number
  default     = 8080

  validation {
    condition = var.server_port > 0 && var.server_port <= 65536
    error_message = "El puerto debe ser un valor entre 1 y 65536"
  }
}

variable "load_balancer_port" {
  description = "Default port form application load balancer"
  type        = number
  default     = 80
}

variable "instance_type" {
  description = "Size of EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "ubuntu_ami" {
  description = "AMIs list"
  type = map(string)

  default = {
    us-east-1 = "ami-0557a15b87f6559cf"
    us-east-2 = "ami-00eeedc4036573771"
  }
}
