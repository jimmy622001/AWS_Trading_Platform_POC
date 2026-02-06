# Export all outputs from the base module
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.base.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.base.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.base.private_subnet_ids
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.base.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster"
  value       = module.base.eks_cluster_endpoint
}