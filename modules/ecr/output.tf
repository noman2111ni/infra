output "repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.ECS_Repository.repository_url
}

output "repository_name" {
  description = "ECR Repository Name"
  value       = aws_ecr_repository.ECS_Repository.name
}

output "repository_arn" {
  description = "ECR Repository ARN"
  value       = aws_ecr_repository.ECS_Repository.arn
}