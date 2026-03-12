# Orbit Network Module
module "orbit_vpc" {
  source       = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-vpc?ref=v1"
  environment  = var.environment
  vpc_name     = "${var.name}-${var.environment}-vpc"
  vpc_cidr     = var.vpc_cidr
  private_list = var.private_subnets
  public_list  = var.public_subnets
  tags = {
    Environment = var.environment
    Name        = "${var.name}-${var.environment}-vpc"
  }
}
# Database Subnets one
resource "aws_subnet" "database_1" {
  vpc_id            = module.orbit_vpc.vpc_id
  cidr_block        = var.database_subnets[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${var.name}-${var.environment}-database-subnet-1"
    Environment = var.environment
    Type        = "Database"
  }
}
# Database Subnets two
resource "aws_subnet" "database_2" {
  vpc_id            = module.orbit_vpc.vpc_id
  cidr_block        = var.database_subnets[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name        = "orbit-database-subnet-2-${var.environment}"
    Environment = var.environment
    Type        = "Database"
  }
}
# Database Route Table
resource "aws_route_table" "database" {
  vpc_id = module.orbit_vpc.vpc_id
  tags = {
    Name        = "orbit-database-rt-${var.environment}"
    Environment = var.environment
  }
}
# Associate Database Subnets with Route Table one
resource "aws_route_table_association" "database_1" {
  subnet_id      = aws_subnet.database_1.id
  route_table_id = aws_route_table.database.id
}
# Associate Database Subnets with Route Table two
resource "aws_route_table_association" "database_2" {
  subnet_id      = aws_subnet.database_2.id
  route_table_id = aws_route_table.database.id
}
# S3 VPC Endpoint (free - always)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.orbit_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.database.id
  ]
  tags = {
    Name        = "orbit-s3-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# VPC Endpoint Security Group (prod only)
resource "aws_security_group" "vpc_endpoints" {
  count       = local.is_prod ? 1 : 0
  name        = "orbit-vpce-sg-${var.environment}"
  description = "Security group for VPC Endpoints"
  vpc_id      = module.orbit_vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTPS from VPC"
  }
  tags = {
    Name        = "orbit-vpce-sg-${var.environment}"
    Environment = var.environment
  }
}
# VPC Endpoints (prod only)
resource "aws_vpc_endpoint" "ecr_api" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "orbit-ecr-api-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# VPC Endpoints (prod only)
resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "orbit-ecr-dkr-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# Secrets Manager Endpoint (prod only)
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "orbit-cloudwatch-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# Secrets Manager Endpoint (prod only)
resource "aws_vpc_endpoint" "secretsmanager" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  tags = {
    Name        = "orbit-secretsmanager-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# SSM Messages Endpoint (prod only)
resource "aws_vpc_endpoint" "ssm" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "orbit-ssm-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# Bedrock Runtime Endpoint (prod only)
resource "aws_vpc_endpoint" "ssmmessages" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  tags = {
    Name        = "orbit-ssmmessages-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# Bedrock Runtime Endpoint (prod only)
resource "aws_vpc_endpoint" "ec2messages" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = {
    Name        = "orbit-ec2messages-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# Bedrock Runtime Endpoint (prod only)
resource "aws_vpc_endpoint" "bedrock_runtime" {
  count               = local.is_prod ? 1 : 0
  vpc_id              = module.orbit_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.orbit_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  tags = {
    Name        = "orbit-bedrock-endpoint-${var.environment}"
    Environment = var.environment
  }
}
# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}
# Locals
locals {
  is_prod = var.environment == "prod"
}
