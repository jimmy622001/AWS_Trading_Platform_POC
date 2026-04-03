# Base module configuration that all environments inherit
# This file contains shared infrastructure code for all environments

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment        = var.environment
      Project            = var.project_name
      ManagedBy          = "terraform"
      CostCenter         = "trading-platform"
      Owner              = "platform-team"
      BackupSchedule     = "daily"
      DataClassification = "confidential"
      ComplianceLevel    = "high"
      AutoShutdown       = "false"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  azs        = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Module calls for different learning areas
module "secrets" {
  source = "../../modules/secrets"

  project_name               = var.project_name
  rancher_bootstrap_password = var.rancher_bootstrap_password
  grafana_admin_password     = var.grafana_admin_password
  rds_master_password        = var.rds_master_password
}

module "networking" {
  source = "../../modules/networking"

  vpc_cidr            = var.vpc_cidr
  azs                 = local.azs
  project_name        = var.project_name
  customer_gateway_ip = var.customer_gateway_ip
  onpremises_cidr     = var.onpremises_cidr
}

module "security" {
  source = "../../modules/security"

  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
}

module "serverless" {
  source = "../../modules/serverless"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  lambda_role_arn    = module.security.lambda_role_arn
  project_name       = var.project_name
}

module "containers" {
  source = "../../modules/containers"

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.eks_security_group_id
  project_name       = var.project_name

  # Environment-specific EKS scaling
  eks_node_desired_size   = var.eks_node_desired_size
  eks_node_max_size       = var.eks_node_max_size
  eks_node_min_size       = var.eks_node_min_size
  eks_node_instance_types = var.eks_node_instance_types
}

module "event_systems" {
  source = "../../modules/event-systems"

  project_name = var.project_name
}

module "cicd" {
  source = "../../modules/cicd"

  project_name = var.project_name
}

module "monitoring" {
  source = "../../modules/monitoring"

  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
}

module "observability" {
  source = "../../modules/observability"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  eks_cluster_name   = module.containers.eks_cluster_name
  project_name       = var.project_name
}

module "load_balancing" {
  source = "../../modules/load-balancing"

  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  project_name      = var.project_name
}

module "prometheus_grafana" {
  source = "../../modules/prometheus-grafana"

  grafana_admin_password = var.grafana_admin_password
}

module "threat_detection" {
  source = "../../modules/threat-detection"

  project_name = var.project_name
}

module "caching" {
  source = "../../modules/caching"

  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  eks_security_group_id = module.security.eks_security_group_id
  project_name          = var.project_name
  redis_auth_token      = var.redis_auth_token
  sns_topic_arn         = module.threat_detection.security_alerts_topic_arn
}

module "trading_optimizations" {
  source = "../../modules/trading-optimizations"

  private_subnet_ids    = module.networking.private_subnet_ids
  eks_security_group_id = module.security.eks_security_group_id
  project_name          = var.project_name
  sns_topic_arn         = module.threat_detection.security_alerts_topic_arn
}

module "dr_automation" {
  source = "../../modules/dr-automation"

  project_name       = var.project_name
  primary_region     = var.aws_region
  dr_region          = var.dr_region
  sns_topic_arn      = module.threat_detection.security_alerts_topic_arn
  primary_alb_name   = module.load_balancing.primary_alb_name
  dr_alb_name        = var.dr_alb_name
  rto_threshold_seconds = var.rto_threshold_seconds
  rpo_threshold_seconds = var.rpo_threshold_seconds
}