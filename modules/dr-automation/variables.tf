variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "dr_region" {
  description = "Disaster recovery AWS region"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for DR test notifications"
  type        = string
}

variable "primary_alb_name" {
  description = "Primary region ALB name"
  type        = string
}

variable "dr_alb_name" {
  description = "DR region ALB name"
  type        = string
}

variable "rto_threshold_seconds" {
  description = "Recovery Time Objective threshold in seconds"
  type        = number
  default     = 300
}

variable "rpo_threshold_seconds" {
  description = "Recovery Point Objective threshold in seconds"
  type        = number
  default     = 60
}
