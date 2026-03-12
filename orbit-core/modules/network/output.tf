output "vpc_id" {
  description = "VPC ID"
  value       = module.orbit_vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = var.vpc_cidr
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.orbit_vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.orbit_vpc.public_subnet_ids
}

output "database_subnet_ids" {
  description = "Database Subnet IDs"
  value       = [aws_subnet.database_1.id, aws_subnet.database_2.id]
}