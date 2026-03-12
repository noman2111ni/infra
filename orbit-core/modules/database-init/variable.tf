variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private Subnet IDs for Lambda"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "RDS Security Group ID"
  type        = string
}
variable "name" {
  description = "Name for the Lambda function"
  type        = string
}
variable "database_url_secret_arn" {
  description = "Database URL Secret ARN"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN"
  type        = string
}

variable "templates_bucket" {}