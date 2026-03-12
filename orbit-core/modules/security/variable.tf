variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from network module"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}