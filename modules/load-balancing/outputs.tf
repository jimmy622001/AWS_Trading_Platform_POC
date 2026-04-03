output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.nlb.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.nlb.dns_name
}

output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = aws_lb.nlb.zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.alb_http.arn
}

output "nlb_target_group_arn" {
  description = "ARN of the NLB target group"
  value       = aws_lb_target_group.nlb_tcp.arn
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "nlb_security_group_id" {
  description = "Security group ID for NLB"
  value       = aws_security_group.nlb.id
}


output "primary_alb_name" {
  description = "Name of the primary Application Load Balancer"
  value       = aws_lb.main.name
}

output "primary_alb_arn" {
  description = "ARN of the primary Application Load Balancer"
  value       = aws_lb.main.arn
}
