output "public_ip" {
  value = aws_instance.carmine_ec2.public_ip
  description = "The public IP of the web server"
}

output "public_dns" {
  value = "http://${aws_instance.carmine_ec2.public_dns}:${var.server_port}"
  description = "The public NDS of the web server"
}