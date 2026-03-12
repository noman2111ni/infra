locals {
  is_prod = var.environment == "prod"
}

#############################################
# Database Credentials Secret
#############################################
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "orbit/${var.environment}/database/credentials"
  description = "Database credentials for Orbit - ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name        = "orbit-db-credentials-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_endpoint
    port     = var.db_port
    dbname   = var.db_name
  })
}

#############################################
# Database URL Secret
#############################################
resource "aws_secretsmanager_secret" "db_url" {
  name        = "orbit/${var.environment}/database/url"
  description = "Database URL for Orbit - ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name        = "orbit-db-url-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id     = aws_secretsmanager_secret.db_url.id
  secret_string = "postgresql://${var.db_username}:${var.db_password}@${var.db_endpoint}:${var.db_port}/${var.db_name}?sslmode=require"
}

#############################################
# Redis Auth Secret
#############################################
resource "aws_secretsmanager_secret" "redis_auth" {
  name        = "orbit/${var.environment}/redis/auth"
  description = "Redis AUTH token for Orbit - ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name        = "orbit-redis-auth-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id
  secret_string = jsonencode({
    token = var.redis_auth_token
  })
}

#############################################
# Redis URL Secret
#############################################
resource "aws_secretsmanager_secret" "redis_url" {
  name        = "orbit/${var.environment}/redis/url"
  description = "Redis URL for Orbit - ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name        = "orbit-redis-url-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id     = aws_secretsmanager_secret.redis_url.id
  secret_string = "rediss://:${var.redis_auth_token}@${var.redis_endpoint}:${var.redis_port}/0"
}

#############################################
# JWT Secret
#############################################
resource "aws_secretsmanager_secret" "jwt" {
  name        = "orbit/${var.environment}/jwt/secret"
  description = "JWT signing secret for Orbit - ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name        = "orbit-jwt-secret-${var.environment}"
    Environment = var.environment
  }
}

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id = aws_secretsmanager_secret.jwt.id
  secret_string = jsonencode({
    secret = random_password.jwt_secret.result
  })
}

#############################################
# Tavily API Key Secret
#############################################
resource "aws_secretsmanager_secret" "tavily_api_key" {
  name        = "orbit/${var.environment}/api-keys/tavily"
  description = "Tavily API Key for Orbit - ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name        = "orbit-tavily-api-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "tavily_api_key" {
  secret_id     = aws_secretsmanager_secret.tavily_api_key.id
  secret_string = jsonencode({ api_key = "" })
}

#############################################
# Admin Credentials Secret
#############################################
resource "aws_secretsmanager_secret" "admin_credentials" {
  name        = "orbit/${var.environment}/admin/credentials"
  description = "Admin credentials for Orbit - ${var.environment}"
  kms_key_id  = var.kms_key_arn

  tags = {
    Name        = "orbit-admin-credentials-${var.environment}"
    Environment = var.environment
  }
}

resource "random_password" "admin_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*"
}

resource "aws_secretsmanager_secret_version" "admin_credentials" {
  secret_id = aws_secretsmanager_secret.admin_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.admin_password.result
  })
}

#############################################
# JWT Rotation (prod only)
#############################################
resource "aws_iam_role" "jwt_rotation" {
  count = local.is_prod ? 1 : 0
  name  = "orbit-jwt-rotation-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "orbit-jwt-rotation-role-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "jwt_rotation_basic" {
  count      = local.is_prod ? 1 : 0
  role       = aws_iam_role.jwt_rotation[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "jwt_rotation_policy" {
  count = local.is_prod ? 1 : 0
  name  = "SecretsRotationPolicy"
  role  = aws_iam_role.jwt_rotation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [aws_secretsmanager_secret.jwt.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

resource "aws_lambda_function" "jwt_rotation" {
  count         = local.is_prod ? 1 : 0
  function_name = "orbit-jwt-rotation-${var.environment}"
  description   = "Rotates JWT signing secret"
  runtime       = "python3.11"
  handler       = "index.handler"
  role          = aws_iam_role.jwt_rotation[0].arn
  timeout       = 30

  filename = "${path.module}/jwt_rotation.zip"

  tags = {
    Name        = "orbit-jwt-rotation-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lambda_permission" "jwt_rotation" {
  count         = local.is_prod ? 1 : 0
  function_name = aws_lambda_function.jwt_rotation[0].function_name
  action        = "lambda:InvokeFunction"
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.jwt.arn
}

resource "aws_secretsmanager_rotation_schedule" "jwt" {
  count               = local.is_prod ? 1 : 0
  secret_id           = aws_secretsmanager_secret.jwt.id
  rotation_lambda_arn = aws_lambda_function.jwt_rotation[0].arn

  rotation_rules {
    automatically_after_days = 90
  }

  depends_on = [aws_lambda_permission.jwt_rotation]
}

#############################################
# Random Provider
#############################################
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}