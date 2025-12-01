# Multi-Region Disaster Recovery with Pilot Light Approach

# Secondary Region Provider
provider "aws" {
  alias  = "dr_region"
  region = var.dr_region

  default_tags {
    tags = {
      Environment = "dr"
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# Data source for DR region AZs
data "aws_availability_zones" "dr_available" {
  provider = aws.dr_region
  state    = "available"
}

locals {
  dr_azs = slice(data.aws_availability_zones.dr_available.names, 0, 2)
}

#######################
# DR Infrastructure 
#######################

# DR VPC
resource "aws_vpc" "dr" {
  provider             = aws.dr_region
  cidr_block           = var.dr_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-dr-vpc"
  }
}

# Internet Gateway for DR VPC
resource "aws_internet_gateway" "dr" {
  provider = aws.dr_region
  vpc_id   = aws_vpc.dr.id

  tags = {
    Name = "${var.project_name}-dr-igw"
  }
}

# Public Subnets for DR region
resource "aws_subnet" "dr_public" {
  provider = aws.dr_region
  count    = length(local.dr_azs)

  vpc_id                  = aws_vpc.dr.id
  cidr_block              = cidrsubnet(var.dr_vpc_cidr, 8, count.index)
  availability_zone       = local.dr_azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-dr-public-${local.dr_azs[count.index]}"
    Type = "Public"
  }
}

# Private Subnets for DR region
resource "aws_subnet" "dr_private" {
  provider = aws.dr_region
  count    = length(local.dr_azs)

  vpc_id            = aws_vpc.dr.id
  cidr_block        = cidrsubnet(var.dr_vpc_cidr, 8, count.index + 10)
  availability_zone = local.dr_azs[count.index]

  tags = {
    Name = "${var.project_name}-dr-private-${local.dr_azs[count.index]}"
    Type = "Private"
  }
}

# NAT Gateway for DR region
resource "aws_eip" "dr_nat" {
  provider   = aws.dr_region
  domain     = "vpc"
  depends_on = [aws_internet_gateway.dr]

  tags = {
    Name = "${var.project_name}-dr-nat-eip"
  }
}

resource "aws_nat_gateway" "dr" {
  provider      = aws.dr_region
  allocation_id = aws_eip.dr_nat.id
  subnet_id     = aws_subnet.dr_public[0].id

  tags = {
    Name = "${var.project_name}-dr-nat"
  }

  depends_on = [aws_internet_gateway.dr]
}

# Route Tables for DR region
resource "aws_route_table" "dr_public" {
  provider = aws.dr_region
  vpc_id   = aws_vpc.dr.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr.id
  }

  tags = {
    Name = "${var.project_name}-dr-public-rt"
  }
}

resource "aws_route_table" "dr_private" {
  provider = aws.dr_region
  vpc_id   = aws_vpc.dr.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dr.id
  }

  tags = {
    Name = "${var.project_name}-dr-private-rt"
  }
}

# Route Table Associations for DR region
resource "aws_route_table_association" "dr_public" {
  provider       = aws.dr_region
  count          = length(local.dr_azs)
  subnet_id      = aws_subnet.dr_public[count.index].id
  route_table_id = aws_route_table.dr_public.id
}

resource "aws_route_table_association" "dr_private" {
  provider       = aws.dr_region
  count          = length(local.dr_azs)
  subnet_id      = aws_subnet.dr_private[count.index].id
  route_table_id = aws_route_table.dr_private.id
}

#######################
# DR Database 
#######################

# DR DB Subnet Group
resource "aws_db_subnet_group" "dr" {
  provider   = aws.dr_region
  name       = "${var.project_name}-dr-db-subnet-group"
  subnet_ids = aws_subnet.dr_private[*].id

  tags = {
    Name = "${var.project_name}-dr-db-subnet-group"
  }
}

# DR Security Group for RDS
resource "aws_security_group" "dr_rds" {
  provider    = aws.dr_region
  name_prefix = "${var.project_name}-dr-rds-"
  vpc_id      = aws_vpc.dr.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.dr_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-dr-rds-sg"
  }
}

# DR RDS Read Replica (Pilot Light)
resource "aws_db_instance" "dr_replica" {
  provider                   = aws.dr_region
  identifier                 = "${var.project_name}-dr-database"
  replicate_source_db        = aws_db_instance.main.arn
  instance_class             = "db.t3.micro" # Smaller instance for cost efficiency
  vpc_security_group_ids     = [aws_security_group.dr_rds.id]
  db_subnet_group_name       = aws_db_subnet_group.dr.name
  skip_final_snapshot        = true
  auto_minor_version_upgrade = true

  # For a pilot light setup, consider:
  multi_az                = false # Can be true for higher DR reliability
  backup_retention_period = 5     # Fewer days than primary 

  tags = {
    Name        = "${var.project_name}-dr-database"
    Environment = "dr"
  }

  depends_on = [aws_db_instance.main]
}

#######################
# DR Object Storage
#######################

# DR S3 Bucket for application data
resource "aws_s3_bucket" "dr" {
  provider      = aws.dr_region
  bucket        = "${var.project_name}-dr-data-${var.aws_account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-dr-data"
  }
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr_region
  bucket   = aws_s3_bucket.dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr" {
  provider = aws.dr_region
  bucket   = aws_s3_bucket.dr.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Replication role
resource "aws_iam_role" "replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# Replication policy
resource "aws_iam_policy" "replication" {
  name = "${var.project_name}-s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.project_name}-data-${var.aws_account_id}"
        ]
      },
      {
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.project_name}-data-${var.aws_account_id}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.project_name}-dr-data-${var.aws_account_id}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Primary S3 bucket for application data
resource "aws_s3_bucket" "primary" {
  bucket        = "${var.project_name}-data-${var.aws_account_id}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-data"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.primary]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "EntireS3Replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD"
    }
  }
}

#######################
# DR Health Checks and DNS Failover
#######################

# Route 53 Health Check for Primary Region
resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_endpoint_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-primary-health-check"
  }
}

# Route 53 Health Check for DR Region
resource "aws_route53_health_check" "dr" {
  fqdn              = var.dr_endpoint_domain
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-dr-health-check"
  }
}

# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.dns_zone_name
}

# Route 53 Failover Record Set for the application
resource "aws_route53_record" "app_failover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.application_domain
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id
  set_identifier  = "primary"

  alias {
    name                   = var.primary_endpoint_domain
    zone_id                = var.primary_dns_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "app_failover_dr" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.application_domain
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = aws_route53_health_check.dr.id
  set_identifier  = "dr"

  alias {
    name                   = var.dr_endpoint_domain
    zone_id                = var.dr_dns_zone_id
    evaluate_target_health = true
  }
}

#######################
# DR EKS Cluster (Pilot Light)
#######################

# DR KMS key for CloudWatch Logs
resource "aws_kms_key" "dr_logs" {
  provider            = aws.dr_region
  description         = "DR KMS key for CloudWatch logs encryption"
  enable_key_rotation = true
}

resource "aws_kms_alias" "dr_logs" {
  provider      = aws.dr_region
  name          = "alias/${var.project_name}-dr-logs"
  target_key_id = aws_kms_key.dr_logs.key_id
}

# CloudWatch Log Group for DR EKS
resource "aws_cloudwatch_log_group" "dr_eks" {
  provider          = aws.dr_region
  name              = "/aws/eks/${var.project_name}-dr/cluster"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.dr_logs.arn
}

# DR EKS Cluster Security Group
resource "aws_security_group" "dr_eks_cluster" {
  provider    = aws.dr_region
  name_prefix = "${var.project_name}-dr-eks-cluster-"
  description = "Security group for DR EKS cluster control plane"
  vpc_id      = aws_vpc.dr.id

  egress {
    description = "HTTPS to internet for EKS API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Communication with worker nodes"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.dr_vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-dr-eks-cluster-sg"
  }
}

# DR EKS Cluster IAM Role (reuse primary role)
resource "aws_eks_cluster" "dr" {
  provider = aws.dr_region
  name     = "${var.project_name}-dr-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids              = aws_subnet.dr_private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"] # Consider restricting in production
    security_group_ids      = [aws_security_group.dr_eks_cluster.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.dr_logs.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit"]

  # Reduced logging compared to primary for cost efficiency

  depends_on = [
    aws_cloudwatch_log_group.dr_eks,
  ]

  tags = {
    Name = "${var.project_name}-dr-eks-cluster"
  }
}

# DR EKS Node Group with minimal size for pilot light approach
resource "aws_eks_node_group" "dr" {
  provider        = aws.dr_region
  cluster_name    = aws_eks_cluster.dr.name
  node_group_name = "${var.project_name}-dr-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.dr_private[*].id
  instance_types  = ["t3.small"] # Smaller instance type for cost efficiency
  capacity_type   = "ON_DEMAND"
  ami_type        = "AL2_x86_64"

  scaling_config {
    desired_size = 1  # Minimal size for pilot light
    max_size     = 10 # Can scale up when needed
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.project_name}-dr-eks-nodes"
  }
}

# Core DNS addon for DR cluster
resource "aws_eks_addon" "dr_coredns" {
  provider     = aws.dr_region
  cluster_name = aws_eks_cluster.dr.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.dr]
}

#######################
# Cross-region DynamoDB Global Table
#######################

resource "aws_dynamodb_table" "primary" {
  name             = "${var.project_name}-session-store"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "SessionId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES" # Required for global tables

  attribute {
    name = "SessionId"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-session-store"
  }
}

resource "aws_dynamodb_table" "dr" {
  provider         = aws.dr_region
  name             = "${var.project_name}-session-store"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "SessionId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "SessionId"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  tags = {
    Name = "${var.project_name}-dr-session-store"
  }
}

resource "aws_dynamodb_global_table" "session_store" {
  depends_on = [aws_dynamodb_table.primary, aws_dynamodb_table.dr]

  name = "${var.project_name}-session-store"

  replica {
    region_name = var.aws_region
  }

  replica {
    region_name = var.dr_region
  }
}

#######################
# CloudWatch Alarms for DR Monitoring
#######################

# CloudWatch Alarm to monitor health of primary region
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  alarm_name          = "${var.project_name}-primary-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This alarm monitors primary region ALB health"

  dimensions = {
    LoadBalancer = var.primary_alb_name
  }

  alarm_actions = [aws_sns_topic.dr_alerts.arn]
}


# Lambda function for automated failover (pseudo code)
resource "aws_iam_role" "dr_failover_lambda" {
  name = "${var.project_name}-dr-failover-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dr_failover_lambda" {
  name = "${var.project_name}-dr-failover-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dr_failover_lambda" {
  role       = aws_iam_role.dr_failover_lambda.name
  policy_arn = aws_iam_policy.dr_failover_lambda.arn
}

resource "aws_lambda_function" "dr_failover" {
  function_name = "${var.project_name}-dr-failover"
  role          = aws_iam_role.dr_failover_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 60

  filename         = "${path.module}/dr_failover_function.zip"
  source_code_hash = filebase64sha256("${path.module}/dr_failover_function.zip")

  environment {
    variables = {
      PRIMARY_REGION     = var.aws_region
      DR_REGION          = var.dr_region
      HOSTED_ZONE_ID     = aws_route53_zone.main.zone_id
      APPLICATION_DOMAIN = var.application_domain
    }
  }
}

# Subscribe the lambda to the SNS topic
resource "aws_sns_topic_subscription" "dr_failover" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.dr_failover.arn
}

resource "aws_lambda_permission" "dr_failover" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_failover.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.dr_alerts.arn
}