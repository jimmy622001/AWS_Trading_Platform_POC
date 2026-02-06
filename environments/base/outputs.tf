output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.containers.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster"
  value       = module.containers.eks_cluster_endpoint
}

output "eks_cluster_alb_name" {
  description = "Name of the ALB associated with the EKS cluster"
  value       = module.containers.eks_cluster_alb_name
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = module.security.kms_key_arn
}