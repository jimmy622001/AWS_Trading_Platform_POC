variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

# Security Variables
variable "rancher_bootstrap_password" {
  description = "Bootstrap password for Rancher"
  type        = string
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "rds_master_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

# Network Variables
variable "customer_gateway_ip" {
  description = "Public IP address for customer gateway"
  type        = string
}

variable "onpremises_cidr" {
  description = "On-premises network CIDR"
  type        = string
}

# EKS Variables
variable "eks_version" {
  description = "EKS cluster version"
  type        = string
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
}