output "cluster_name" {
  description = "ECS Cluster Name"
  value       = module.ecs_cluster.cluster_id
}
output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = module.ecs_cluster.cluster_arn
}
output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = module.alb.lb_dns_name
}
output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.lb_arn
}

output "alb_listener_arn" {
  description = "ALB Listener ARN"
  value       = module.alb.https_listener_arn
}

output "log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.ecs.name
}