output "placement_group_name" {
  description = "Name of the placement group"
  value       = aws_placement_group.trading_cluster.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.trading_optimized.id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.trading_engines.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.trading_engines.arn
}
