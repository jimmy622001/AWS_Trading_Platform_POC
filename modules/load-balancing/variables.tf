variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for load balancer"
  type        = list(string)
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}
