variable "primary_region" {
  description = "The AWS region for the primary deployment"
  type        = string
}

variable "dr_region" {
  description = "The AWS region for the DR deployment"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "primary_alb_name" {
  description = "Name of the ALB in the primary region"
  type        = string
}

variable "dr_alb_name" {
  description = "Name of the ALB in the DR region"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "dr_environment" {
  description = "DR Environment name"
  type        = string
}