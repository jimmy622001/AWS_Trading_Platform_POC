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


# DR Configuration Variables
variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
}

variable "dr_alb_name" {
  description = "DR region ALB name"
  type        = string
}

variable "rto_threshold_seconds" {
  description = "Recovery Time Objective threshold in seconds"
  type        = number
}

variable "rpo_threshold_seconds" {
  description = "Recovery Point Objective threshold in seconds"
  type        = number
}

# Caching Variables
variable "redis_auth_token" {
  description = "Redis authentication token"
  type        = string
  sensitive   = true
}


# Caching Configuration
variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
}

variable "cache_num_nodes" {
  description = "Number of cache nodes"
  type        = number
}

# Trading Optimizations Configuration
variable "trading_instance_type" {
  description = "EC2 instance type for trading engines"
  type        = string
}

variable "trading_cpu_cores" {
  description = "Number of CPU cores for trading instances"
  type        = number
}

variable "trading_min_size" {
  description = "Minimum number of trading engine instances"
  type        = number
}

variable "trading_max_size" {
  description = "Maximum number of trading engine instances"
  type        = number
}

variable "trading_desired_size" {
  description = "Desired number of trading engine instances"
  type        = number
}
