# KMS Key
resource "aws_kms_key" "orbit" {
  description         = "KMS key for Orbit Core Agent encryption - ${var.environment}"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  tags = {
    Name        = "orbit-kms-${var.environment}"
    Environment = var.environment
  }
}
# KMS Alias
resource "aws_kms_alias" "orbit" {
  name          = "alias/orbit-${var.environment}"
  target_key_id = aws_kms_key.orbit.key_id
}
# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution" {
  name = "orbit-ecs-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  #   managed_policy_arns = [
  #     "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  #   ]
  tags = {
    Name        = "orbit-ecs-execution-role-${var.environment}"
    Environment = var.environment
  }
}
# ALB IAM Execution Role
resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# Custom policy for ECS Task Execution Role to access Secrets Manager, SSM Parameter Store, and KMS
resource "aws_iam_role_policy" "ecs_execution_policy" {
  name = "SecretsAndParameterAccess"
  role = aws_iam_role.ecs_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:orbit/${var.environment}/*"
        ]
      },
      {
        Sid    = "SSMParameterAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/*"
        ]
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}
# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "orbit-ecs-task-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = "orbit-ecs-task-role-${var.environment}"
    Environment = var.environment
  }
}
# ECS Task Role Policy
resource "aws_iam_role_policy" "bedrock_access" {
  name = "BedrockAccess"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:Converse",
          "bedrock:ConverseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/*"
        ]
      },
      {
        Sid    = "BedrockList"
        Effect = "Allow"
        Action = [
          "bedrock:ListFoundationModels",
          "bedrock:GetFoundationModel",
          "bedrock:ListInferenceProfiles",
          "bedrock:GetInferenceProfile"
        ]
        Resource = "*"
      },
      {
        Sid    = "BedrockKnowledgeBase"
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = [
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
        ]
      }
    ]
  })
}
# Additional policies for ECS Task Role to access AWS Marketplace, S3, and KMS
resource "aws_iam_role_policy" "marketplace_access" {
  name = "AWSMarketplaceAccess"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MarketplaceModelSubscriptions"
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe",
          "aws-marketplace:Unsubscribe",
          "aws-marketplace:GetEntitlements"
        ]
        Resource = "*"
      }
    ]
  })
}
# Custom policy for ECS Task Role to access S3 buckets used by Orbit and KMS
resource "aws_iam_role_policy" "s3_access" {
  name = "S3Access"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3AssetsReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::orbit-assets-${data.aws_caller_identity.current.account_id}-${var.region}",
          "arn:aws:s3:::orbit-assets-${data.aws_caller_identity.current.account_id}-${var.region}/*",
          "arn:aws:s3:::orbit-rag-${data.aws_caller_identity.current.account_id}-${var.region}",
          "arn:aws:s3:::orbit-rag-${data.aws_caller_identity.current.account_id}-${var.region}/*",
          "arn:aws:s3:::orbit-datalake-${data.aws_caller_identity.current.account_id}-${var.region}",
          "arn:aws:s3:::orbit-datalake-${data.aws_caller_identity.current.account_id}-${var.region}/*"
        ]
      },
      {
        Sid    = "S3AuditReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::orbit-audit-${data.aws_caller_identity.current.account_id}-${var.region}",
          "arn:aws:s3:::orbit-audit-${data.aws_caller_identity.current.account_id}-${var.region}/*"
        ]
      }
    ]
  })
}
# Custom policy for ECS Task Role to access KMS for decryption and data key generation
resource "aws_iam_role_policy" "secrets_parameter_access" {
  name = "SecretsAndParameterRead"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:orbit/${var.environment}/*"
        ]
      },
      {
        Sid    = "SSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/*"
        ]
      }
    ]
  })
}
# Custom policy for ECS Task Role to access Secrets Manager and SSM Parameter Store
resource "aws_iam_role_policy" "kms_access" {
  name = "KMSAccess"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KMSDecryptEncrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}
# Security Groups
resource "aws_security_group" "alb" {
  name        = "orbit-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.orbit_vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name        = "orbit-alb-sg-${var.environment}"
    Environment = var.environment
  }
}
# Security group for ECS Tasks
resource "aws_security_group" "ecs" {
  name        = "orbit-ecs-sg-${var.environment}"
  description = "Security group for ECS Tasks"
  vpc_id      = module.orbit_vpc.vpc_id
  ingress {
    from_port       = 9900
    to_port         = 9900
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB on port 9900"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name        = "orbit-ecs-sg-${var.environment}"
    Environment = var.environment
  }
}
# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "orbit-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.orbit_vpc.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
    description     = "Allow PostgreSQL from ECS Tasks"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name        = "orbit-rds-sg-${var.environment}"
    Environment = var.environment
  }
}
# Security group for ElastiCache Redis
resource "aws_security_group" "elasticache" {
  name        = "orbit-elasticache-sg-${var.environment}"
  description = "Security group for ElastiCache Redis"
  vpc_id      = module.orbit_vpc.vpc_id
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
    description     = "Allow Redis from ECS Tasks"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name        = "orbit-elasticache-sg-${var.environment}"
    Environment = var.environment
  }
}
# Data Sources
data "aws_caller_identity" "current" {}
