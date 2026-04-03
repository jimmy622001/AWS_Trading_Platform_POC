variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for trading engines"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "EKS security group ID"
  type        = string
}

variable "trading_instance_type" {
  description = "EC2 instance type for trading engines (compute-optimized)"
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

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
}
