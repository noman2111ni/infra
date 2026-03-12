locals {
  is_prod = var.environment == "prod"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
module "ecs_cluster" {
  source      = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-cluster?ref=v1"
  environment = var.environment
}
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}-${var.environment}-api"
  retention_in_days = local.is_prod ? 30 : 7

  tags = {
    Name        = "${var.name}-${var.environment}-api-logs"
    Environment = var.environment
  }
}
module "alb" {
  source      = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-alb?ref=main"
  environment = var.environment
  region      = var.region
  lb_name     = "${var.name}-alb"
  vpc_name    = "${var.name}-${var.environment}-vpc"

  http_listener_rules = [
    {
      priority     = 1000
      path_pattern = ["/*"]
      host_header  = ["*"]
      tg_name      = "${var.name}-api"
    }
  ]
  https_listener_rules = var.acm_certificate_arn != "" ? [
    {
      priority     = 1000
      path_pattern = ["/*"]
      host_header  = ["*"]
      tg_name      = "${var.name}-api"
    }
  ] : []

  certificate_arn = var.acm_certificate_arn

  ingress_list = [
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
    ]
  egress_list = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]
}

resource "aws_ecs_task_definition" "orbit_api" {
  family                   = "${var.name}-${var.environment}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = local.is_prod ? "1024" : "512"
  memory                   = local.is_prod ? "2048" : "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
    container_definitions = jsonencode([
    {
      name      = "orbit-api"
      image     = "${var.ecr_repository_uri}:${var.container_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 9900
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "AWS_REGION",       value = data.aws_region.current.name },
        { name = "UVICORN_WORKERS",  value = local.is_prod ? "4" : "2" }
      ]
      secrets = [
        # Secrets Manager
        { name = "DATABASE_URL",   valueFrom = var.database_url_secret_arn },
        { name = "REDIS_URL",      valueFrom = var.redis_url_secret_arn },
        { name = "JWT_SECRET",     valueFrom = "${var.jwt_secret_arn}:secret::" },
        { name = "ADMIN_USERNAME", valueFrom = "${var.admin_credentials_secret_arn}:username::" },
        { name = "ADMIN_PASSWORD", valueFrom = "${var.admin_credentials_secret_arn}:password::" },
        # SSM - General
        { name = "ENVIRONMENT",    valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/general/environment" },
        { name = "PORT",           valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/general/port" },
        { name = "LOG_LEVEL",      valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/general/log_level" },
        { name = "CLOUD_PROVIDER", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/general/cloud_provider" },
        { name = "ENABLE_DEBUG",   valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/general/enable_debug" },
        # SSM - LLM
        { name = "LLM_PROVIDER",                valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/llm/provider" },
        { name = "BEDROCK_MODEL_ID",             valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/llm/model_id" },
        { name = "AWS_BEDROCK_EMBEDDING_MODEL",  valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/llm/embedding_model" },
        { name = "BEDROCK_USE_CONVERSE_API",     valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/llm/use_converse_api" },
        { name = "BEDROCK_ENABLE_CROSS_REGION",  valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/llm/enable_cross_region" },
        # SSM - Storage
        { name = "STORAGE_BACKEND",       valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/backend" },
        { name = "ASSET_STORAGE_BUCKET",  valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/assets_bucket" },
        { name = "RAG_S3_BUCKET",         valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/rag_bucket" },
        { name = "DATALAKE_S3_BUCKET",    valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/datalake_bucket" },
        { name = "ASSET_STORAGE_BACKEND", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/asset_backend" },
        { name = "S3_REGION",             valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/s3_region" },
        { name = "ASSET_S3_REGION",       valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/s3_region" },
        { name = "AUDIT_S3_REGION",       valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/s3_region" },
        { name = "S3_BUCKET_NAME",        valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/rag_bucket_alias" },
        # SSM - Audit
        { name = "AUDIT_LOGGING_ENABLED",  valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/audit/enabled" },
        { name = "AUDIT_STORAGE_BACKEND",  valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/audit/storage_backend" },
        { name = "AUDIT_S3_BUCKET",        valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/storage/audit_bucket" },
        { name = "PII_MASKING_ENABLED",    valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/audit/pii_masking" },
        { name = "PII_MASKING_LEVEL",      valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/audit/masking_level" },
        # SSM - AWS Integration
        { name = "USE_SECRETS_MANAGER", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/aws/use_secrets_manager" },
        { name = "USE_PARAMETER_STORE", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/aws/use_parameter_store" },
        # SSM - Observability
        { name = "OBSERVABILITY_ENABLED", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/observability/enabled" },
        { name = "OBSERVABILITY_PROFILE", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/observability/profile" },
        { name = "SERVICE_NAME",          valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/observability/service_name" },
        # SSM - Security
        { name = "JWT_ALGORITHM",                   valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/security/jwt_algorithm" },
        { name = "JWT_ACCESS_TOKEN_EXPIRE_MINUTES",  valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/security/jwt_expire_minutes" },
        { name = "JWT_VERIFY_SIGNATURE",             valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/security/jwt_verify_signature" },
        { name = "ENFORCE_REGION_RESTRICTION",       valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/security/enforce_region_restriction" },
        { name = "ALLOWED_AWS_REGIONS",              valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/security/allowed_regions" },
        { name = "JWT_DEV_MODE_SKIP_VERIFICATION",   valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/security/jwt_dev_mode_skip" },
        # SSM - API
        { name = "CORS_ORIGINS",                  valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/api/cors_origins" },
        { name = "RATE_LIMITING_ENABLED",          valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/api/rate_limiting" },
        { name = "RATE_LIMIT_REQUESTS_PER_MINUTE", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/api/rate_limit_rpm" },
        # SSM - Database Retry
        { name = "DB_INIT_MAX_RETRIES", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/database/init_max_retries" },
        { name = "DB_INIT_RETRY_DELAY", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/database/init_retry_delay" },
        # SSM - MCP
        { name = "MCP_GATEWAY_HOST", valueFrom = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/orbit/${var.environment}/mcp/gateway_host" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/orbit-api-${var.environment}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "orbit-api"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9900/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 120
      }
    }
  ])
  tags = {
    Name        = "${var.name}-${var.environment}-api-task"
    Environment = var.environment
  }
}
module "ecs_service" {
  source      = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-ecs-service?ref=v1.0.0"
  environment = var.environment
  cluster_id  = module.ecs_cluster.cluster_id

  service_name     = "${var.name}-${var.environment}-api"
  vpc_name         = "${var.name}-${var.environment}-vpc"
  target_group_arn = module.alb.https_tg["0"].arn
  container_name   = "${var.name}-api"

  ingress_list = [
    { from_port = 9900, to_port = 9900, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]
  egress_list = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ] # depends_on  = [module_alb]
}
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = local.is_prod ? 10 : 3
  min_capacity       = local.is_prod ? 2 : 1
  resource_id        = "service/${module.ecs_cluster.cluster_id}/${var.name}-api-${var.environment}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [module.ecs_service]
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.name}-${var.environment}-cpu-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       =  70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count               = local.is_prod ? 1 : 0
  alarm_name          = "${var.name}-${var.environment}-alb-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy targets"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
    TargetGroup  = module.alb.tg_arn_suffix
  }

  tags = {
    Environment = var.environment
  }
}
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  count               = local.is_prod ? 1 : 0
  alarm_name          = "${var.name}-${var.environment}-alb-response-time"
  alarm_description   = "ALB response time is high"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions          = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }

  tags = {
    Environment = var.environment
  }
}
resource "aws_cloudwatch_metric_alarm" "ecs_5xx_errors" {
  count               = local.is_prod ? 1 : 0
  alarm_name          = "${var.name}-${var.environment}-ecs-5xx-errors"
  alarm_description   = "ECS service returning 5xx errors"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
    TargetGroup  = module.alb.tg_arn_suffix
  }

  tags = {
    Environment = var.environment
  }
}