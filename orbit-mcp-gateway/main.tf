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

locals {
  is_prod                  = var.environment == "prod"
  create_ecr               = var.ecr_repository_uri == ""
  create_cluster           = var.existing_cluster_name == ""
  create_service_discovery = var.service_discovery_namespace_id == ""
  has_listener             = var.alb_listener_arn != "" && var.mcp_gateway_hostname != ""
}

data "aws_caller_identify" "current" {}
data "aws_region" "current" {}

module "ecr" {
  count                = local.create_ecr ? 1 : 0
  source               = "./modules/ecr"
  name                 = "${var.name}-${var.environment}-mcp-gateway"
  environment          = var.environment
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  lifecycle_policy     = 10
}
module "ecs_cluster" {
  count  = local.create_cluster ? 1 : 0
  source = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-cluster?ref=v1"

  environment = var.environment
}
resource "aws_cloudwatch_log_group" "mcp_gateway" {
  name              = "/ecs/${var.name}-${var.environment}-mcp-gateway"
  retention_in_days = local.is_prod ? 30 : 7

  tags = {
    Name        = "${var.name}-${var.environment}-mcp-gateway-logs"
    Environment = var.environment
  }
}
resource "aws_lb_target_group" "dashboard" {
  count       = local.has_listener ? 1 : 0
  name        = "${var.name}-${var.environment}-mcp-tg"
  vpc_id      = var.vpc_id
  protocol    = "HTTP"
  port        = 7700
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.name}-${var.environment}-mcp-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "mcp_gateway" {
  count        = local.has_listener ? 1 : 0
  listener_arn = var.alb_listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dashboard[0].arn
  }
  condition {
    host_header {
      values = [var.mcp_gateway_hostname]
    }
  }
}
resource "aws_service_discovery_private_dns_namespace" "orbit" {
  count       = local.create_service_discovery ? 1 : 0
  name        = var.service_discovery_namespace_name
  vpc         = var.vpc_id
  description = "Private DNS namespace for ${var.name} services"
  tags = {
    Name        = "${var.name}-${var.environment}-sd-namespace"
    Environment = var.environment
  }
}

resource "aws_service_discovery_service" "mcp_gateway" {
  name         = "mcp-gateway"
  namespace_id = local.create_service_discovery ? aws_service_discovery_private_dns_namespace.orbit[0].id : var.service_discovery_namespace_id
  description  = "MCP Gateway service discovery"
  dns_config {
    namespace_id   = local.create_service_discovery ? aws_service_discovery_private_dns_namespace.orbit[0].id : var.service_discovery_namespace_id
    routing_policy = "MULTIVALUE"
    dns_records {
      type = "A"
      ttl  = 60
    }
  }
  health_check_config {
    failure_threshold = 1
  }
  tags = {
    Name        = "mcp-gateway-discovery-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role" "mcp_gateway_execution" {
  name = "${var.name}-${var.environment}-mcp-gateway-execution-role"

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
    Name        = "${var.name}-${var.environment}-mcp-gateway-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "mcp_gateway_logs" {
  name = "MCPGatewayLogsPolicy"
  role = aws_iam_role.mcp_gateway_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/orbit-mcp-gateway-${var.environment}:*"
    }]
  })
}
resource "aws_ecs_task_defination" "mcp_gateway" {
  family                   = "${var.name}-${var.environment}-mcp-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.is_prod ? "1024" : "512"
  memory                   = local.is_prod ? "2048" : "1024"
  execution_role_arn       = aws_iam_role.mcp_gateway_execution.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "mcp-gateway"
      image     = local.create_ecr ? "${module.ecr.repository_url}:latest" : "${var.ecr_repository_uri}:latest"
      essential = true
      portMappings = [
        { containerPort = 7700, protocol = "tcp", name = "dashboard" },
        { containerPort = 7701, protocol = "tcp", name = "data-science" },
        { containerPort = 7702, protocol = "tcp", name = "development" },
        { containerPort = 7703, protocol = "tcp", name = "production" },
        { containerPort = 7704, protocol = "tcp", name = "testing" }
      ]
      environment = [
        { name = "LOG_LEVEL", value = local.is_prod ? "INFO" : "DEBUG" },
        { name = "CONFIG_DIR", value = "/app/config" },
        { name = "PYTHONPATH", value = "/app/src" },
        { name = "ENVIRONMENT", value = var.environment },
        { name = "DISABLE_DASHBOARD", value = "false" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name}-${var.environment}-mcp-gateway"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "mcp-gateway"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:7700/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 60
      }
    }
  ])
  tags = {
    Name        = "orbit-mcp-gateway-task-${var.environment}"
    Environment = var.environment
  }
}
resource "aws_ecs_service" "mcp_gateway" {
  name             = "orbit-mcp-gateway-${var.environment}"
  cluster          = local.create_cluster ? module.ecs_cluster[0].cluster_id : "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.existing_cluster_name}"
  task_definition  = aws_ecs_task_definition.mcp_gateway.arn
  desired_count    = local.is_prod ? 2 : 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.mcp_gateway.id]
    subnets          = var.private_subnet_ids
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mcp_gateway.arn
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  enable_execute_command = true

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = local.is_prod ? 100 : 50

  tags = {
    Name        = "orbit-mcp-gateway-service-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_iam_role_policy_attachment.mcp_gateway_execution]
}

#############################################
# Auto Scaling (prod only)
#############################################
resource "aws_appautoscaling_target" "mcp_gateway" {
  count              = local.is_prod ? 1 : 0
  max_capacity       = 5
  min_capacity       = 2
  resource_id        = "service/${var.existing_cluster_name != "" ? var.existing_cluster_name : "orbit-cluster-${var.environment}"}/orbit-mcp-gateway-${var.environment}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.mcp_gateway]
}

resource "aws_appautoscaling_policy" "mcp_gateway_cpu" {
  count              = local.is_prod ? 1 : 0
  name               = "orbit-mcp-gateway-cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.mcp_gateway[0].resource_id
  scalable_dimension = aws_appautoscaling_target.mcp_gateway[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.mcp_gateway[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

#############################################
# SSM Parameter (optional)
#############################################
resource "aws_ssm_parameter" "mcp_gateway_host" {
  count = var.update_ssm_parameter ? 1 : 0
  name  = "/orbit/${var.environment}/mcp/gateway_host"
  type  = "String"
  value = "mcp-gateway.${var.service_discovery_namespace_name}"

  tags = {
    Environment = var.environment
  }
}

#############################################
# CloudWatch Alarm (prod only)
#############################################
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count               = local.is_prod ? 1 : 0
  alarm_name          = "orbit-mcp-gateway-health-${var.environment}"
  alarm_description   = "MCP Gateway health check failures"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  tags = {
    Environment = var.environment
  }
}
