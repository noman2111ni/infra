terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.1"
    }
  }
}
provider "aws" {
  region = var.region
}
#############################################
# VPC Module
#############################################
module "ez_vpc" {
  source       = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-vpc?ref=v1"
  environment  = var.environment
  vpc_name     = "${var.environment}-ezleagues"
  vpc_cidr     = var.vpc_cidr
  private_list = var.private_subnets
  public_list  = var.public_subnets
}
#############################################
# ECS Cluster Module
#############################################
module "ez_cluster" {
  source      = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-cluster?ref=v1"
  environment = var.environment
}
#############################################
# ALB Module
#############################################
module "alb" {
  source      = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-alb?ref=main"
  environment = var.environment
  region      = var.region
  lb_name     = "ezleagues"
  vpc_name    = "${var.environment}-ezleagues-vpc"
  http_listener_rules = [
    {
      priority     = 10
      path_pattern = ["/mcp", "/mcp/*"]
      host_header  = ["ezleagues.com"]
      tg_name      = "ezleagues-mcp"
    },
    {
      priority     = 1000
      path_pattern = ["/*"]
      host_header  = ["ezleagues.com"]
      tg_name      = "ezleagues-api"
    }
  ]
  https_listener_rules = [
    {
      priority     = 10
      path_pattern = ["/mcp", "/mcp/*"]
      host_header  = ["ezleagues.com"]
      tg_name      = "ezleagues-mcp"
    },
    {
      priority     = 1000
      path_pattern = ["/*"]
      host_header  = ["ezleagues.com"]
      tg_name      = "ezleagues-api"
    }
  ]
  certificate_arn = var.certificate_arn
  ingress_list = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_list = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
#############################################
# ECR - API
#############################################
module "ecr_api" {
  source               = "./modules/ecr"
  name                 = "ezfacility-ezleagues-api"
  environment          = var.environment
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  lifecycle_policy     = 10
}
#############################################
# ECR - MCP
#############################################
module "ecr_mcp" {
  source               = "./modules/ecr"
  name                 = "ezfacility-ezleagues-mcp"
  environment          = var.environment
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  lifecycle_policy     = 10
}
#############################################
# ECS Service - API
#############################################
module "api_service" {
  source           = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-service?ref=v1.0.0"
  environment      = var.environment
  cluster_id       = module.ez_cluster.cluster_id
  service_name     = "ezfacility-ezleagues-api"
  vpc_name         = "${var.environment}-ezleagues-vpc"
  target_group_arn = module.alb.https_tg["0"].arn
  container_name   = "ezleagues-api-container"
  ingress_list = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_list = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
#############################################
# ECS Service - MCP
#############################################
module "mcp_service" {
  source           = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-service?ref=v1.0.0"
  environment      = var.environment
  cluster_id       = module.ez_cluster.cluster_id
  service_name     = "ezfacility-ezleagues-mcp"
  vpc_name         = "${var.environment}-ezleagues-vpc"
  target_group_arn = module.alb.https_tg["1"].arn
  container_name   = "ezleagues-mcp-container"

  ingress_list = [
    {
      from_port   = 8010
      to_port     = 8010
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_list = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}