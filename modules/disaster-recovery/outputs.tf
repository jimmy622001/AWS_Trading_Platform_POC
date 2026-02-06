output "backup_vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.main.name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

# Multi-region DR outputs
output "dr_region" {
  description = "Disaster Recovery AWS region"
  value       = var.dr_region
}

output "dr_rds_endpoint" {
  description = "DR RDS instance endpoint"
  value       = aws_db_instance.dr_replica.endpoint
}

output "dr_eks_cluster_name" {
  description = "DR EKS cluster name"
  value       = aws_eks_cluster.dr.name
}

output "dr_vpc_id" {
  description = "DR VPC ID"
  value       = aws_vpc.dr.id
}

output "dr_private_subnet_ids" {
  description = "DR private subnet IDs"
  value       = aws_subnet.dr_private[*].id
}

output "dr_public_subnet_ids" {
  description = "DR public subnet IDs"
  value       = aws_subnet.dr_public[*].id
}

output "s3_replication_status" {
  description = "Indicates that S3 bucket replication is configured"
  value       = "Enabled between ${var.aws_region} and ${var.dr_region}"
}

output "route53_dns_failover" {
  description = "Indicates that Route 53 DNS failover is configured"
  value       = "Primary: ${var.primary_endpoint_domain}, Secondary: ${var.dr_endpoint_domain}"
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = var.kms_key_arn
}

output "spot_to_ondemand_function_arn" {
  description = "ARN of the Lambda function that converts spot to on-demand instances"
  value       = aws_lambda_function.spot_to_ondemand.arn
}

output "revert_to_spot_function_arn" {
  description = "ARN of the Lambda function that reverts to spot instances"
  value       = aws_lambda_function.revert_to_spot.arn
}
