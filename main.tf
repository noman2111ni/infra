terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.1"
    }
  }
}

# Configure the AWS provider

provider "aws" {
  region = var.region
}

# define variable
variable "environment" {}
variable "region" {}
variable "certificate_arn" {}


# call the module to create the VPC

module "ez_vpc" {
  source       = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-vpc?ref=v1"
  application  = "ezui"
  environment  = "test"
  vpc_cidr     = "10.25.0.0/16"
  private_list = ["10.25.64.0/20", "10.25.32.0/20"]
  public_list  = ["10.25.96.0/20", "10.25.112.0/20"]
}
#  call the module to create the ECS cluster
module "ez_cluster" {
  source      = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-cluster?ref=v1"
  application = "ez-leagues"
  environment = var.environment
}

# call the module to create the ALB

module "alb" {
  source      = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-alb?ref=main"
  environment = "test"
  region      = "us-east-1"
  lb_name     = "ezui"
  vpc_name    = "${var.environment}-ezui-vpc"
  http_listener_rules = [
    {
      priority     = 1
      path_pattern = ["static/*"]
      host_header  = ["test.com"]

    }
  ]
  https_listener_rules = [
    {
      priority     = 1
      path_pattern = ["static/*"]
      host_header  = ["test.com"]

  }, ]

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


# Call the module to create the ECS service

module "web_service" {
  source           = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-service?ref=v1.0.0"
  environment      = "test"
  cluster_id       = module.ez_cluster.cluster_id
  service_name     = "web"
  vpc_name         = "test-ezui-vpc"
  target_group_arn = module.alb.target_group_arn
  container_name   = "filestore-container"
  ingress_list = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }]
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
# ECR - API
#############################################
module "ecr_api" {
  source               = "./modules/ecr"
  ECR_Repo_name        = "ezfacility-ezleagues-api"
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
  ECR_Repo_name        = "ezfacility-ezleagues-mcp"
  environment          = var.environment
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  lifecycle_policy     = 10
}




# ECS Service - API


module "api_service" {
  source           = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-service?ref=v1.0.0"
  environment      = var.environment
  cluster_id       = module.ez_cluster.cluster_id
  service_name     = "ezfacility-ezleagues-api"
  vpc_name         = "${var.environment}-ezui-vpc"
  target_group_arn = module.alb.target_group_arn
  container_name   = "ezleagues_api-container"

  ingress_list = [
    {
      from_port = 8080
      to_port   = 8080
      protocol  = "tcp"
      cidr      = ["0.0.0.0/0"]
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
# ECS Service - MCP
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
