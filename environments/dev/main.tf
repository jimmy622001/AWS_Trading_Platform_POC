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
    path = "terraform.dev.tfstate"
  }
}

module "base" {
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