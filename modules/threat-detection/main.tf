# GuardDuty for threat detection
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }

  tags = {
    Name = "${var.project_name}-guardduty"
  }
}

# Security Hub for compliance monitoring
resource "aws_securityhub_account" "main" {}

# Enable CIS AWS Foundations Benchmark
resource "aws_securityhub_standards_subscription" "cis" {
  depends_on      = [aws_securityhub_account.main]
  standards_arn   = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# Enable PCI DSS
resource "aws_securityhub_standards_subscription" "pci_dss" {
  depends_on      = [aws_securityhub_account.main]
  standards_arn   = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
}

# CloudWatch Event Rule for GuardDuty Findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [7, 7.0, 7.1, 7.2, 7.3, 8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 9, 9.0, 9.1, 9.2, 9.3]
    }
  })
}

# CloudWatch Event Rule for Security Hub Findings
resource "aws_cloudwatch_event_rule" "security_hub_findings" {
  name        = "${var.project_name}-security-hub-findings"
  description = "Capture Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL", "HIGH"]
        }
      }
    }
  })
}

# SNS Topic for Security Alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts"

  tags = {
    Name = "${var.project_name}-security-alerts"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# CloudWatch Event Target for GuardDuty
resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyFindings"
  arn       = aws_sns_topic.security_alerts.arn
}

# CloudWatch Event Target for Security Hub
resource "aws_cloudwatch_event_target" "security_hub_sns" {
  rule      = aws_cloudwatch_event_rule.security_hub_findings.name
  target_id = "SecurityHubFindings"
  arn       = aws_sns_topic.security_alerts.arn
}

# CloudWatch Dashboard for Security
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.project_name}-security-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SecurityHub", "ComplianceScore"],
            [".", "CriticalFindingsCount"],
            [".", "HighFindingsCount"]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Security Hub Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | filter @message like /GuardDuty/ | stats count() by bin(5m)"
          region  = data.aws_region.current.name
          title   = "GuardDuty Findings"
        }
      }
    ]
  })
}

# Lambda function for automated remediation
resource "aws_iam_role" "remediation_lambda" {
  name = "${var.project_name}-remediation-lambda-role"

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

resource "aws_iam_role_policy_attachment" "remediation_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.remediation_lambda.name
}

resource "aws_iam_role_policy" "remediation_lambda_policy" {
  name = "${var.project_name}-remediation-lambda-policy"
  role = aws_iam_role.remediation_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:DescribeSecurityGroups",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_region" "current" {}
