# Production Region Variables
variable "aws_region" {
  description = "AWS region for production resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for Production VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod)"
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

# EKS Variables for Production
variable "eks_version" {
  description = "EKS cluster version"
  type        = string
}

variable "eks_node_instance_types" {
  description = "Instance types for Production EKS node group"
  type        = list(string)
}

variable "eks_node_desired_size" {
  description = "Desired number of Production EKS nodes"
  type        = number
}

variable "eks_node_max_size" {
  description = "Maximum number of Production EKS nodes"
  type        = number
}

variable "eks_node_min_size" {
  description = "Minimum number of Production EKS nodes"
  type        = number
}

# DR Region Variables
variable "dr_region" {
  description = "AWS region for DR resources"
  type        = string
}

variable "dr_vpc_cidr" {
  description = "CIDR block for DR VPC"
  type        = string
}

# EKS Variables for DR
variable "dr_eks_node_instance_types" {
  description = "Instance types for DR EKS node group (typically spot instances)"
  type        = list(string)
}

variable "dr_eks_node_desired_size" {
  description = "Desired number of DR EKS nodes"
  type        = number
}

variable "dr_eks_node_max_size" {
  description = "Maximum number of DR EKS nodes"
  type        = number
}

variable "dr_eks_node_min_size" {
  description = "Minimum number of DR EKS nodes"
  type        = number
}

# Common Variables
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}