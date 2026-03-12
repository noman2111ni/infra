# network variables
variable "environment" {}
variable "region" {}
variable "vpc_cidr" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "database_subnets" {}
variable "name" {}
# Storage variables
variable "use_existing_assets_bucket" {}
variable "use_existing_audit_bucket" {}
variable "use_existing_rag_bucket" {}
variable "use_existing_datalake_bucket" {}

# cache variables
variable "redis_auth_token" {}
variable "name_redis" {}

# database variables
variable "db_username" {}
variable "templates_bucket" {}

# compute variables
variable "ecr_repository_uri" {}
variable "container_image_tag" {}
variable "acm_certificate_arn" {}
variable "alarm_sns_topic_arn" {}


# 
variable "alert_email" {}


variable "domain_name" {}
variable "mcp_gateway_host" {}