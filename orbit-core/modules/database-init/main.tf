locals {
  is_prod = var.environment == "prod"
}

#############################################
# Lambda Security Group
#############################################
resource "aws_security_group" "db_init_lambda" {
  name        = "${var.name}-${var.environment}-db-init-lambda-sg"
  description = "Security group for DB Init Lambda"
  vpc_id      = module.orbit_vpc.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "orbit-db-init-lambda-sg-${var.environment}"
    Environment = var.environment
  }
}

#############################################
# Allow Lambda to connect to RDS
#############################################
resource "aws_security_group_rule" "rds_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_init_lambda.id
  security_group_id        = var.rds_security_group_id
  description              = "Allow PostgreSQL from DB Init Lambda"
}

#############################################
# Lambda Module
#############################################
module "db_init_lambda" {
  source = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-lambda?ref=v1"

  environment   = var.environment
  function_name = "orbit-db-init"
  runtime       = "python3.11"
  handler       = "index.handler"
  timeout       = 300
  memory_size   = 512

  source_s3 = {
    source_s3_bucket = var.templates_bucket
    source_s3_key    = "lambda/db-init-lambda.zip"
  }

  vpc_name = "orbit-vpc-${var.environment}"

  lambda_env_variables = {
    DATABASE_URL_SECRET_ARN = var.database_url_secret_arn
    TEMPLATES_BUCKET        = var.templates_bucket
  }

  tags = {
    Name        = "orbit-db-init-${var.environment}"
    Environment = var.environment
  }

  depends_on = [
    aws_security_group_rule.rds_ingress_from_lambda
  ]
}

#############################################
# Trigger Lambda
#############################################
resource "aws_lambda_invocation" "db_init" {
  function_name = module.db_init_lambda.function_name

  input = jsonencode({
    Version = "5.0.0-full-schema"
  })

  depends_on = [module.db_init_lambda]
}




# output 
output "lambda_arn" {
  description = "DB Init Lambda ARN"
  value       = module.db_init_lambda.lambda_arn
}