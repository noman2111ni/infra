variable "environment" {
  description = "Environment (dev/qa/prod/test)"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = "vpc-0757d659a4f7ea145"
}

variable "public_subnet_ids" {
  description = "Public Subnet IDs for ALB"
  type        = list(string)
  default     = ["subnet-08cc5ac11cb675593",
                 "subnet-0c7f917398dab598c"]
}

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
  default     = ""
}