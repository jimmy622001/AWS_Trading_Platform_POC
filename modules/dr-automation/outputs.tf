output "dr_test_lambda_function_name" {
  description = "Name of the DR test Lambda function"
  value       = aws_lambda_function.dr_test.function_name
}

output "dr_test_lambda_arn" {
  description = "ARN of the DR test Lambda function"
  value       = aws_lambda_function.dr_test.arn
}

output "dr_test_schedule_rule_name" {
  description = "Name of the EventBridge rule for DR testing"
  value       = aws_cloudwatch_event_rule.dr_test_schedule.name
}

output "dr_test_log_group_name" {
  description = "CloudWatch log group name for DR tests"
  value       = aws_cloudwatch_log_group.dr_test_logs.name
}
