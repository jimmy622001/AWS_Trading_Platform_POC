output "health_check_id" {
  description = "ID of the Route53 health check for failover"
  value       = aws_route53_health_check.primary.id
}

output "failover_record_name" {
  description = "The fully qualified domain name of the failover record"
  value       = aws_route53_record.primary.fqdn
}