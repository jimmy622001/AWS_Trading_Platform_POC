# AWS Trading Platform - Multi-Environment Terraform Project
# This project uses an environment-based approach with directories for prod, dev, and dr environments
# See environments/ directory for environment-specific configurations

# This root main.tf file is intentionally minimal
# Each environment manages its own state and configurations

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# For an environment-based approach, we don't define resources in the root module
# Please navigate to environments/prod, environments/dev, or environments/dr directories
# to deploy the specific environment configurations
