# Lambda function for automated DR testing
resource "aws_iam_role" "dr_test_lambda" {
  name = "${var.project_name}-dr-test-lambda-role"

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

resource "aws_iam_role_policy_attachment" "dr_test_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.dr_test_lambda.name
}

resource "aws_iam_role_policy" "dr_test_lambda_policy" {
  name = "${var.project_name}-dr-test-lambda-policy"
  role = aws_iam_role.dr_test_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetHealthCheckStatus",
          "route53:ListHealthChecks",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "dynamodb:DescribeTable",
          "s3:ListBucket",
          "sns:Publish",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function code
resource "aws_lambda_function" "dr_test" {
  filename      = "${path.module}/dr_test_function.zip"
  function_name = "${var.project_name}-dr-test"
  role          = aws_iam_role.dr_test_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300

  environment {
    variables = {
      PRIMARY_REGION        = var.primary_region
      DR_REGION             = var.dr_region
      SNS_TOPIC_ARN         = var.sns_topic_arn
      PRIMARY_ALB_NAME      = var.primary_alb_name
      DR_ALB_NAME           = var.dr_alb_name
      RTO_THRESHOLD_SECONDS = var.rto_threshold_seconds
      RPO_THRESHOLD_SECONDS = var.rpo_threshold_seconds
    }
  }

  source_code_hash = filebase64sha256("${path.module}/dr_test_function.zip")
}

# EventBridge Rule for scheduled DR testing (monthly)
resource "aws_cloudwatch_event_rule" "dr_test_schedule" {
  name                = "${var.project_name}-dr-test-schedule"
  description         = "Scheduled DR testing - first Saturday of each month"
  schedule_expression = "cron(0 2 ? * SAT#1 *)"

  tags = {
    Name = "${var.project_name}-dr-test-schedule"
  }
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "dr_test_lambda" {
  rule      = aws_cloudwatch_event_rule.dr_test_schedule.name
  target_id = "DRTestLambda"
  arn       = aws_lambda_function.dr_test.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_test.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_test_schedule.arn
}

# CloudWatch Log Group for DR testing
resource "aws_cloudwatch_log_group" "dr_test_logs" {
  name              = "/aws/lambda/${var.project_name}-dr-test"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-dr-test-logs"
  }
}

# CloudWatch Alarms for DR testing
resource "aws_cloudwatch_metric_alarm" "dr_test_failures" {
  alarm_name          = "${var.project_name}-dr-test-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when DR test fails"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    FunctionName = aws_lambda_function.dr_test.function_name
  }
}

# CloudWatch Dashboard for DR metrics
resource "aws_cloudwatch_dashboard" "dr_metrics" {
  dashboard_name = "${var.project_name}-dr-metrics"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", { stat = "Average" }],
            [".", "Errors", { stat = "Sum" }],
            [".", "Invocations", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "DR Test Execution Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | filter @message like /RTO|RPO/ | stats avg(rto_seconds) as avg_rto, avg(rpo_seconds) as avg_rpo"
          region  = var.primary_region
          title   = "RTO/RPO Metrics"
        }
      }
    ]
  })
}
