output "parameter_prefix" {
  description = "SSM Parameter prefix"
  value       = "/${var.name}/${var.environment}"
}

locals {
  # is_test = var.environment == "test" 
  # is_dev  = var.environment == "dev"
  is_prod = var.environment == "prod"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# Genral Configuration
resource "aws_ssm_parameter" "environment" {
  name  = "/${var.name}/${var.environment}/environment"
  type  = "String"
  value = var.environment
  tags = {
    Environment = var.environment
  }
}

resource "aws_ssm_perameter" "log_level" {
  name  = "/${var.name}/${var.environment}/general/log_level"
  type  = "String"
  value = local.is_prod ? "INFO" : "DEBUG"
  tags = {
    Environment = var.environment
  }
}
resource "aws_ssm_perameter" "domain_name" {
  name  = "${var.name}/${var.environment}/general/domain_name"
  type  = "String"
  value = var.domain_name
  tags = {
    Environment = var.environment
  }
}

resource "aws_ssm_perameter" "port" {
  name  = "${var.name}/${var.environment}/general/port"
  type  = "String"
  value = "9900"
  tags = {
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "cloud_provider" {
  name  = "/${var.name}/${var.environment}/general/cloud_provider"
  type  = "String"
  value = "aws"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "enable_debug" {
  name  = "/${var.name}/${var.environment}/general/enable_debug"
  type  = "String"
  value = local.is_prod ? "false" : "true"
  tags  = { Environment = var.environment }
}

# Database Configuration
resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.name}/${var.environment}/database/host"
  type  = "String"
  value = var.db_host
  tags  = { Environment = var.environment }
}
resource "aws_ssm_parameter" "cloud_provider" {
  name  = "/${var.name}/${var.environment}/general/cloud_provider"
  type  = "String"
  value = "aws"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "enable_debug" {
  name  = "/${var.name}/${var.environment}/general/enable_debug"
  type  = "String"
  value = local.is_prod ? "false" : "true"
  tags  = { Environment = var.environment }
}

# Database Configuration
resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.name}/${var.environment}/database/host"
  type  = "String"
  value = var.db_host
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.name}/${var.environment}/database/port"
  type  = "String"
  value = var.db_port
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.name}/${var.environment}/database/name"
  type  = "String"
  value = var.db_name
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_ssl_mode" {
  name  = "/${var.name}/${var.environment}/database/ssl_mode"
  type  = "String"
  value = "require"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_init_max_retries" {
  name  = "/${var.name}/${var.environment}/database/init_max_retries"
  type  = "String"
  value = "10"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_init_retry_delay" {
  name  = "/${var.name}/${var.environment}/database/init_retry_delay"
  type  = "String"
  value = "5.0"
  tags  = { Environment = var.environment }
}

# Redis Configuration
resource "aws_ssm_parameter" "redis_host" {
  name  = "/${var.name}/${var.environment}/redis/host"
  type  = "String"
  value = var.redis_host
  tags  = { Environment = var.environment }
}
resource "aws_ssm_parameter" "redis_port" {
  name  = "/${var.name}/${var.environment}/redis/port"
  type  = "String"
  value = var.redis_port
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "redis_ssl" {
  name  = "/${var.name}/${var.environment}/redis/ssl"
  type  = "String"
  value = "true"
  tags  = { Environment = var.environment }
}

# Storage Configuration
resource "aws_ssm_parameter" "storage_backend" {
  name  = "/${var.name}/${var.environment}/storage/backend"
  type  = "String"
  value = "s3"
  tags  = { Environment = var.environment }
}


resource "aws_ssm_parameter" "assets_bucket" {
  name  = "/${var.name}/${var.environment}/storage/assets_bucket"
  type  = "String"
  value = var.assets_bucket_name
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "audit_bucket" {
  name  = "/${var.name}/${var.environment}/storage/audit_bucket"
  type  = "String"
  value = var.audit_bucket_name
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "rag_bucket" {
  name  = "/${var.name}/${var.environment}/storage/rag_bucket"
  type  = "String"
  value = var.rag_bucket_name
  tags  = { Environment = var.environment }
}
resource "aws_ssm_parameter" "datalake_bucket" {
  name  = "/${var.name}/${var.environment}/storage/datalake_bucket"
  type  = "String"
  value = var.datalake_bucket_name
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "asset_backend" {
  name  = "/${var.name}/${var.environment}/storage/asset_backend"
  type  = "String"
  value = "s3"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "s3_region" {
  name  = "/${var.name}/${var.environment}/storage/s3_region"
  type  = "String"
  value = data.aws_region.current.name
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "rag_bucket_alias" {
  name  = "/${var.name}/${var.environment}/storage/rag_bucket_alias"
  type  = "String"
  value = var.assets_bucket_name
  tags  = { Environment = var.environment }
}

# AWS Integration
resource "aws_ssm_parameter" "use_secrets_manager" {
  name  = "/${var.name}/${var.environment}/aws/use_secrets_manager"
  type  = "String"
  value = "true"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "use_parameter_store" {
  name  = "/${var.name}/${var.environment}/aws/use_parameter_store"
  type  = "String"
  value = "true"
  tags  = { Environment = var.environment }
}

# LLM Configuration
resource "aws_ssm_parameter" "llm_provider" {
  name  = "/${var.name}/${var.environment}/llm/provider"
  type  = "String"
  value = "bedrock"
  tags  = { Environment = var.environment }
}
resource "aws_ssm_parameter" "llm_model_id" {
  name  = "/${var.name}/${var.environment}/llm/model_id"
  type  = "String"
  value = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "llm_embedding_model" {
  name  = "/${var.name}/${var.environment}/llm/embedding_model"
  type  = "String"
  value = "amazon.titan-embed-text-v2:0"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "llm_region" {
  name  = "/${var.name}/${var.environment}/llm/region"
  type  = "String"
  value = data.aws_region.current.name
  tags  = { Environment = var.environment }
}
resource "aws_ssm_parameter" "llm_model_id" {
  name  = "/${var.name}/${var.environment}/llm/model_id"
  type  = "String"
  value = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "llm_embedding_model" {
  name  = "/${var.name}/${var.environment}/llm/embedding_model"
  type  = "String"
  value = "amazon.titan-embed-text-v2:0"
  tags  = { Environment = var.environment }
}

resource "aws_ssm_parameter" "llm_region" {
  name  = "/${var.name}/${var.environment}/llm/region"
  type  = "String"
  value = data.aws_region.current.name
  tags  = { Environment = var.environment }
}
