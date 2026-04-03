# Placement Group for ultra-low latency trading
resource "aws_placement_group" "trading_cluster" {
  name     = "${var.project_name}-trading-cluster"
  strategy = "cluster"

  tags = {
    Name = "${var.project_name}-trading-cluster"
  }
}

# Launch Template with enhanced networking for ultra-low latency
resource "aws_launch_template" "trading_optimized" {
  name_prefix   = "${var.project_name}-trading-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.trading_instance_type

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [var.eks_security_group_id]

    # Enable enhanced networking (SR-IOV, ENA)
    ipv4_address_count = 1
  }

  # Enable detailed monitoring for latency tracking
  monitoring {
    enabled = true
  }

  # CPU options for performance
  cpu_options {
    core_count       = var.trading_cpu_cores
    threads_per_core = 2
  }

  # Metadata options for security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-trading-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-trading-volume"
    }
  }
}

# Auto Scaling Group with placement group for trading engines
resource "aws_autoscaling_group" "trading_engines" {
  name                = "${var.project_name}-trading-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.trading_min_size
  max_size            = var.trading_max_size
  desired_capacity    = var.trading_desired_size
  placement_group     = aws_placement_group.trading_cluster.name

  launch_template {
    id      = aws_launch_template.trading_optimized.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-trading-engine"
    propagate_at_launch = true
  }

  tag {
    key                 = "Type"
    value               = "TradingEngine"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Dashboard for latency monitoring
resource "aws_cloudwatch_dashboard" "latency_monitoring" {
  dashboard_name = "${var.project_name}-latency-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            [".", "NetworkIn", { stat = "Sum" }],
            [".", "NetworkOut", { stat = "Sum" }]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Trading Engine Performance"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkPacketsIn", { stat = "Sum" }],
            [".", "NetworkPacketsOut", { stat = "Sum" }]
          ]
          period = 60
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Network Packet Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarms for latency
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.project_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkLatency"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Alert when network latency exceeds 1ms"
  alarm_actions       = [var.sns_topic_arn]
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_region" "current" {}
