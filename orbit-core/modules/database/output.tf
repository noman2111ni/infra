output "db_endpoint" {
  description = "RDS Endpoint"
  value       = module.orbit_rds.db_endpoint
}

output "db_port" {
  description = "RDS Port"
  value       = module.orbit_rds.db_port
}

output "db_name" {
  description = "Database Name"
  value       = "orbit_db"
}