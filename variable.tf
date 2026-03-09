variable "environment" {
  description = "Environment (dev/qa/prod/test)"
  type        = string
}
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
variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
}
