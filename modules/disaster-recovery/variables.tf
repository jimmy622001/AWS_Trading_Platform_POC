variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

# Multi-region DR variables
variable "dr_region" {
  description = "AWS region for disaster recovery"
  type        = string
}

variable "dr_vpc_cidr" {
  description = "CIDR block for the DR VPC"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
}

variable "dns_zone_name" {
  description = "Route 53 hosted zone name"
  type        = string
}

variable "application_domain" {
  description = "Domain name for the application"
  type        = string
}

variable "primary_endpoint_domain" {
  description = "Endpoint domain for the primary region"
  type        = string
}

variable "dr_endpoint_domain" {
  description = "Endpoint domain for the DR region"
  type        = string
}

variable "primary_dns_zone_id" {
  description = "Route 53 hosted zone ID for primary ALB"
  type        = string
}

variable "dr_dns_zone_id" {
  description = "Route 53 hosted zone ID for DR ALB"
  type        = string
}

variable "primary_alb_name" {
  description = "Name of the primary region ALB for CloudWatch metrics"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "rds_master_password" {
  description = "Master password for RDS database"
  type        = string
  sensitive   = true
}
