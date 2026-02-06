resource "aws_route53_health_check" "primary" {
  fqdn              = "${var.primary_alb_name}.${var.primary_region}.elb.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name        = "${var.project_name}-primary-health-check"
    Environment = var.environment
  }
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary"
  alias {
    name                   = "${var.primary_alb_name}.${var.primary_region}.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K" # Fixed ALB zone ID for all regions
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"
  alias {
    name                   = "${var.dr_alb_name}.${var.dr_region}.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K" # Fixed ALB zone ID for all regions
    evaluate_target_health = true
  }
}