locals {
  is_prod = var.environment == "prod"
}
# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "orbit" {
  name        = "${var.name_redis}-${var.environment}-cache-subnet-group"
  description = "Subnet group for Orbit ElastiCache - ${var.environment}"
  subnet_ids  = var.database_subnet_ids

  tags = {
    Name        = "${var.name_redis}-${var.environment}-cache-subnet-group"
    Environment = var.environment
  }
}
# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "orbit" {
  name        = "${var.name_redis}-${var.environment}-cache-params"
  family      = "redis7"
  description = "Parameter group for Orbit Redis 7.1 - ${var.environment}"

  parameter {
    name  = "notify-keyspace-events"
    value = "AKE"
  }
  tags = {
    Name        = "${var.name_redis}-${var.environment}-cache-params"
    Environment = var.environment
  }
}
# ElastiCache Redis Replication Group
resource "aws_elasticache_replication_group" "orbit" {
  replication_group_id = "${var.name_redis}-${var.environment}-redis"
  description          = "Orbit Core Agent Redis cluster - ${var.environment}"

  engine             = "redis"
  engine_version     = "7.1"
  node_type          = local.is_prod ? "cache.r6g.large" : "cache.t4g.micro"
  num_cache_clusters = local.is_prod ? 2 : 1
  port               = 6379
  automatic_failover_enabled = local.is_prod ? true : false
  multi_az_enabled           = local.is_prod ? true : false
  subnet_group_name            = aws_elasticache_subnet_group.orbit.name
  parameter_group_name         = aws_elasticache_parameter_group.orbit.name
  security_group_ids           = [var.elasticache_security_group_id]
  maintenance_window = "sun:05:00-sun:06:00"
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  snapshot_retention_limit   = local.is_prod ? 7 : 1
  snapshot_window            = "04:00-05:00"
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.name_redis}-${var.environment}-redis"
    Environment = var.environment
  }
}
# CloudWatch Alarms (prod only)
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  count               = local.is_prod ? 1 : 0
  alarm_name          = "${var.name_redis}-${var.environment}-redis-cpu"
  alarm_description   = "Redis CPU utilization is high"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 75
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = "${var.name_redis}-${var.environment}-redis-001"
  }

  tags = {
    Name        = "${var.name_redis}-${var.environment}-redis-cpu-alarm"
    Environment = var.environment
  }
}
# CloudWatch Alarms (prod only)
resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  count               = local.is_prod ? 1 : 0
  alarm_name          = "${var.name_redis}-${var.environment}-redis-memory"
  alarm_description   = "Redis memory usage is high"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = "${var.name_redis}-${var.environment}-redis-001"
  }

  tags = {
    Name        = "${var.name_redis}-${var.environment}-redis-memory-alarm"
    Environment = var.environment
  }
}
# cloudwatch alarm for redis connections (prod only)
resource "aws_cloudwatch_metric_alarm" "redis_connections" {
  count               = local.is_prod ? 1 : 0
  alarm_name          = "${var.name_redis}-${var.environment}-redis-connections"
  alarm_description   = "Redis connections are high"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 1000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions = {
    CacheClusterId = "${var.name_redis}-${var.environment}-redis-001"
  }
  tags = {
    Name        = "${var.name_redis}-${var.environment}-redis-connections-alarm"
    Environment = var.environment
  }
}
