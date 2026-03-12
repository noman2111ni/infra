variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}
variable "name" {}
variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "csiorbit.com"
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "orbit_db"
}

variable "redis_host" {
  description = "Redis host endpoint"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = string
  default     = "6379"
}

variable "assets_bucket_name" {
  description = "Assets S3 bucket name"
  type        = string
}

variable "audit_bucket_name" {
  description = "Audit S3 bucket name"
  type        = string
}

variable "rag_bucket_name" {
  description = "RAG S3 bucket name"
  type        = string
}

variable "datalake_bucket_name" {
  description = "Datalake S3 bucket name"
  type        = string
}

variable "mcp_gateway_host" {
  description = "MCP Gateway hostname"
  type        = string
  default     = ""
}