output "elasticache_replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.order_book.id
}

output "elasticache_endpoint" {
  description = "Primary endpoint of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.order_book.primary_endpoint_address
}

output "elasticache_port" {
  description = "Port of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.order_book.port
}

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache"
  value       = aws_security_group.elasticache.id
}
