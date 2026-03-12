output "ecr_repository_uri" {
  description = "ECR Repository URI"
  value       = local.create_ecr ? module.ecr[0].repository_url : var.ecr_repository_uri
}

output "cluster_name" {
  description = "ECS Cluster Name"
  value       = local.create_cluster ? module.ecs_cluster[0].cluster_id : var.existing_cluster_name
}

output "service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.mcp_gateway.name
}
output "mcp_gateway_host" {
  description = "MCP Gateway hostname"
  value       = "mcp-gateway.${var.service_discovery_namespace_name}"
}

output "security_group_id" {
  description = "MCP Gateway Security Group ID"
  value       = aws_security_group.mcp_gateway.id
}

output "service_discovery_namespace_id" {
  description = "Service Discovery Namespace ID"
  value       = local.create_service_discovery ? aws_service_discovery_private_dns_namespace.orbit[0].id : var.service_discovery_namespace_id
}

output "log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.mcp_gateway.name
}