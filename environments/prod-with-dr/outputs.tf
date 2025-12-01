# Production outputs
output "prod_vpc_id" {
  description = "The ID of the Production VPC"
  value       = module.prod.vpc_id
}

output "prod_vpc_cidr" {
  description = "The CIDR block of the Production VPC"
  value       = var.vpc_cidr
}

output "prod_eks_cluster_name" {
  description = "Name of the Production EKS cluster"
  value       = module.prod.eks_cluster_name
}

output "prod_eks_cluster_endpoint" {
  description = "Endpoint for Production EKS control plane"
  value       = module.prod.eks_cluster_endpoint
}

output "prod_eks_cluster_alb_name" {
  description = "Name of the Production ALB"
  value       = "${module.prod.eks_cluster_name}-alb" # Constructing ALB name from cluster name
}

# DR outputs
output "dr_vpc_id" {
  description = "The ID of the DR VPC"
  value       = module.dr.vpc_id
}

output "dr_vpc_cidr" {
  description = "The CIDR block of the DR VPC"
  value       = var.dr_vpc_cidr
}

output "dr_eks_cluster_name" {
  description = "Name of the DR EKS cluster"
  value       = module.dr.eks_cluster_name
}

output "dr_eks_cluster_endpoint" {
  description = "Endpoint for DR EKS control plane"
  value       = module.dr.eks_cluster_endpoint
}

# Failover configuration outputs - temporarily commented out
# output "route53_health_check_id" {
#   description = "ID of the Route53 health check for failover"
#   value       = module.route53_failover.health_check_id
# }
# 
# output "route53_failover_record_name" {
#   description = "The fully qualified domain name of the failover record"
#   value       = module.route53_failover.failover_record_name
# }

output "dr_lambda_functions" {
  description = "ARNs of the DR Lambda functions"
  value = {
    spot_to_ondemand = module.dr_specific.spot_to_ondemand_function_arn
    revert_to_spot   = module.dr_specific.revert_to_spot_function_arn
  }
}