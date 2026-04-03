# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-cache-subnet-group"
  }
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-elasticache-"
  description = "Security group for ElastiCache"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "Allow Redis from EKS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-elasticache-sg"
  }
}

# ElastiCache Redis Replication Group for order book caching with multi-AZ
resource "aws_elasticache_replication_group" "order_book" {
  replication_group_id       = "${var.project_name}-order-book-cache"
  description                = "Redis cluster for order book caching"
  engine                     = "redis"
  node_type                  = var.cache_node_type
  num_cache_clusters         = var.cache_num_nodes
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  engine_version             = "7.0"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.elasticache.id]

  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  snapshot_retention_limit = 5
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "sun:05:00-sun:07:00"

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = {
    Name = "${var.project_name}-order-book-cache"
  }

  depends_on = [aws_elasticache_parameter_group.main]
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  family = "redis7"
  name   = "${var.project_name}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "tcp-keepalive"
    value = "300"
  }

  tags = {
    Name = "${var.project_name}-redis-params"
  }
}

# CloudWatch Log Groups for Redis
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.project_name}/slow-log"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-redis-slow-log"
  }
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${var.project_name}/engine-log"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-redis-engine-log"
  }
}

# CloudWatch Alarms for ElastiCache
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  alarm_name          = "${var.project_name}-cache-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Alert when ElastiCache CPU is high"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.order_book.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  alarm_name          = "${var.project_name}-cache-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Alert when ElastiCache memory usage is high"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.order_book.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cache_evictions" {
  alarm_name          = "${var.project_name}-cache-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "Alert when cache evictions occur"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.order_book.id
  }
}
