output "redis_primary_endpoint" {
  description = "Redis Primary Endpoint"
  value       = aws_elasticache_replication_group.orbit.primary_endpoint_address
}
output "redis_port" {
  description = "Redis Port"
  value       = aws_elasticache_replication_group.orbit.port
}
output "redis_replication_group_id" {
  description = "Redis Replication Group ID"
  value       = aws_elasticache_replication_group.orbit.id
}