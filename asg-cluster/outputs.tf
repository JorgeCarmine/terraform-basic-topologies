output "alb_dns" {
  value = aws_lb.web_app_lb.dns_name
  description = "DNS of load balancer"
}