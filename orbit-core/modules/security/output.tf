output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.orbit.arn
}

output "kms_key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.orbit.key_id
}

output "ecs_execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS Task Role ARN"
  value       = aws_iam_role.ecs_task.arn
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS Security Group ID"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "ElastiCache Security Group ID"
  value       = aws_security_group.elasticache.id
}