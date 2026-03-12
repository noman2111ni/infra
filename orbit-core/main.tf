terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.1"
    }
  }
}

# Initialize AWS provider
provider "aws" {
  region = var.region
}
# Initialize modules
module "network_stack" {
  source           = "./modules/network"
  environment      = var.environment
  region           = var.region
  vpc_cidr         = var.vpc_cidr
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  name             = var.name
}
# Initialize security module
module "security_stack" {
  source      = "./modules/security"
  environment = var.environment
  region      = var.region
  vpc_id      = module.network_stack.vpc_id
  vpc_cidr    = var.vpc_cidr

}
# Initialize storage module
module "storage_stack" {
  source                       = "./modules/storage"
  environment                  = var.environment
  region                       = var.region
  use_existing_assets_bucket   = var.use_existing_assets_bucket
  use_existing_audit_bucket    = var.use_existing_audit_bucket
  use_existing_rag_bucket      = var.use_existing_rag_bucket
  use_existing_datalake_bucket = var.use_existing_datalake_bucket

}
# Initialize cache module
module "cache_stack" {
  source                        = "./modules/cache"
  environment                   = var.environment
  database_subnet_ids           = module.network_stack.database_subnet_ids
  elasticache_security_group_id = module.security_stack.elasticache_security_group_id
  redis_auth_token              = var.redis_auth_token
  name_redis                    = "${var.name}-redis"
}
# Initialize database module
module "database_stack" {
  source      = "./modules/database"
  environment = var.environment
  db_username = var.db.username
}
# Initialize database init module
#############################################
# Database Init Module
#############################################
module "database_init_stack" {
  source      = "./modules/database-init"
  environment = var.environment

  vpc_id                  = module.network_stack.vpc_id
  private_subnet_ids      = module.network_stack.private_subnet_ids
  rds_security_group_id   = module.security_stack.rds_security_group_id
  database_url_secret_arn = module.secrets_stack.database_url_secret_arn
  kms_key_arn             = module.security_stack.kms_key_arn
  templates_bucket        = var.templates_bucket
  name                    = var.name
}


#############################################
# Compute Module
#############################################
module "compute_stack" {
  source                       = "./modules/compute"
  environment                  = var.environment
  region                       = var.region
  ecs_task_execution_role_arn  = module.security_stack.ecs_execution_role_arn
  ecs_task_role_arn            = module.security_stack.ecs_task_role_arn
  database_url_secret_arn      = module.secrets_stack.database_url_secret_arn
  redis_url_secret_arn         = module.secrets_stack.redis_url_secret_arn
  jwt_secret_arn               = module.secrets_stack.jwt_secret_arn
  admin_credentials_secret_arn = module.secrets_stack.admin_credentials_secret_arn
  ecr_repository_uri           = var.ecr_repository_uri
  container_image_tag          = var.container_image_tag
  acm_certificate_arn          = var.acm_certificate_arn
  alarm_sns_topic_arn          = var.alarm_sns_topic_arn
  name                         = var.name
}
# Alerting Module
#############################################
module "alerting_stack" {
  source      = "./modules/alerting"
  environment = var.environment
  name        = "${var.name}-alerts"
  alert_emails = [var.alert_email]
}

#############################################
# Parameters Module
#############################################
module "parameters_stack" {
  source      = "./modules/parameters"
  environment = var.environment
  domain_name          = var.domain_name
  db_host              = module.database_stack.db_endpoint
  db_port              = module.database_stack.db_port
  db_name              = module.database_stack.db_name
  redis_host           = module.cache_stack.redis_primary_endpoint
  redis_port           = module.cache_stack.redis_port
  assets_bucket_name   = module.storage_stack.assets_bucket_name
  audit_bucket_name    = module.storage_stack.audit_bucket_name
  rag_bucket_name      = module.storage_stack.rag_bucket_name
  datalake_bucket_name = module.storage_stack.datalake_bucket_name
  mcp_gateway_host     = var.mcp_gateway_host
  name = var.name
}