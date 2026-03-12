variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}
variable "name" {}
variable "region" {
  description = "AWS Region"
  type        = string
}
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}
variable "private_subnets" {
  description = "Private Subnet CIDRs"
  type        = list(string)
}
variable "public_subnets" {
  description = "Public Subnet CIDRs"
  type        = list(string)
}
variable "database_subnets" {
  description = "Database Subnet CIDRs"
  type        = list(string)
}