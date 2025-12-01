terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # In production, you'd configure a remote backend like S3
  backend "local" {
    path = "terraform.prod-with-dr.tfstate"
  }
}

# Production Region Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# DR Region Provider
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Environment = "${var.environment}-dr"
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_availability_zones" "available_dr" {
  provider = aws.dr
  state    = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  account_id     = data.aws_caller_identity.current.account_id
  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  dr_azs         = slice(data.aws_availability_zones.available_dr.names, 0, 2)
  dr_environment = "${var.environment}-dr"
}

# Production Region Deployment
module "prod" {
  source = "../base"

  # Pass through all variables to the base module
  aws_region                 = var.aws_region
  vpc_cidr                   = var.vpc_cidr
  environment                = var.environment
  project_name               = var.project_name
  rancher_bootstrap_password = var.rancher_bootstrap_password
  grafana_admin_password     = var.grafana_admin_password
  rds_master_password        = var.rds_master_password
  customer_gateway_ip        = var.customer_gateway_ip
  onpremises_cidr            = var.onpremises_cidr
  eks_version                = var.eks_version
  eks_node_instance_types    = var.eks_node_instance_types
  eks_node_desired_size      = var.eks_node_desired_size
  eks_node_max_size          = var.eks_node_max_size
  eks_node_min_size          = var.eks_node_min_size
}

# DR Region Deployment
module "dr" {
  source = "../base"

  # Using the provider from the DR region
  aws_region                 = var.dr_region
  vpc_cidr                   = var.dr_vpc_cidr
  environment                = local.dr_environment
  project_name               = var.project_name
  rancher_bootstrap_password = var.rancher_bootstrap_password
  grafana_admin_password     = var.grafana_admin_password
  rds_master_password        = var.rds_master_password
  customer_gateway_ip        = var.customer_gateway_ip
  onpremises_cidr            = var.onpremises_cidr
  eks_version                = var.eks_version
  eks_node_instance_types    = var.dr_eks_node_instance_types
  eks_node_desired_size      = var.dr_eks_node_desired_size
  eks_node_max_size          = var.dr_eks_node_max_size
  eks_node_min_size          = var.dr_eks_node_min_size
}

# Disaster Recovery specific setup using spot instances
module "dr_specific" {
  source = "../../modules/disaster-recovery"

  vpc_id             = module.dr.vpc_id
  vpc_cidr           = var.dr_vpc_cidr
  private_subnet_ids = module.dr.private_subnet_ids
  project_name       = var.project_name
  aws_region         = var.aws_region
  dr_region          = var.dr_region
  kms_key_arn        = module.dr.kms_key_arn # Module output needs to be fixed
  aws_account_id     = local.account_id

  # DR-specific settings
  primary_alb_name        = "${module.prod.eks_cluster_name}-alb" # Constructing ALB name from cluster name
  application_domain      = var.domain_name
  dns_zone_name           = var.domain_name
  primary_endpoint_domain = module.prod.eks_cluster_endpoint
  dr_endpoint_domain      = module.dr.eks_cluster_endpoint
}

# Route53 Failover Configuration
module "route53_failover" {
  source = "../../modules/disaster-recovery/failover"

  primary_region   = var.aws_region
  dr_region        = var.dr_region
  domain_name      = var.domain_name
  primary_alb_name = "${module.prod.eks_cluster_name}-alb" # Constructing ALB name from cluster name
  dr_alb_name      = "${module.dr.eks_cluster_name}-alb" # Constructing ALB name from cluster name
  project_name     = var.project_name
  environment      = var.environment
  dr_environment   = local.dr_environment
}