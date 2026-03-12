variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "orbit_admin"
  sensitive   = true
}