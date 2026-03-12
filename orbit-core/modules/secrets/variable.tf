variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "Database endpoint"
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

variable "redis_auth_token" {
  description = "Redis AUTH token"
  type        = string
  sensitive   = true
}

variable "redis_endpoint" {
  description = "Redis endpoint"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = string
  default     = "6379"
}