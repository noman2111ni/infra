module "orbit_rds" {
  source = "git::https://ezfacility@dev.azure.com/ezfacility/Infra/_git/module-aws-rds?ref=v1"

  environment               = var.environment
  identifier                = "orbit-postgres"
  engine                    = "postgres"
  engine_version            = "18.1"
  instance_class            = local.is_prod ? "db.r6g.large" : local.is_staging ? "db.t4g.medium" : "db.t4g.small"
  allocated_storage         = local.is_prod ? 100 : 20
  max_allocated_storage     = local.is_prod ? 500 : 100
  storage_type              = "gp3"
  username                  = var.db_username
  port                      = 5432
  storage_encrypted         = true
  enable_storage_encryption = true
  multi_az                  = local.is_prod ? true : false
  iops                      = 0
  publicly_accessible       = false
  skip_final_snapshot       = local.is_prod ? false : true
  final_snapshot_identifier = local.is_prod ? "orbit-postgres-${var.environment}-final" : null
  deletion_protection       = local.is_prod ? true : false
  backup_window             = "03:00-04:00"
  backup_retention_period   = local.is_prod ? 30 : 7
  backup_target             = "region"

  db_parameter = [
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements"
      apply_method = "pending-reboot"
    },
    {
      name         = "max_connections"
      value        = local.is_prod ? "200" : "100"
      apply_method = "immediate"
    },
    {
      name         = "work_mem"
      value        = local.is_prod ? "65536" : "32768"
      apply_method = "immediate"
    },
    {
      name         = "maintenance_work_mem"
      value        = local.is_prod ? "524288" : "262144"
      apply_method = "immediate"
    },
    {
      name         = "log_statement"
      value        = "ddl"
      apply_method = "immediate"
    },
    {
      name         = "log_min_duration_statement"
      value        = local.is_prod ? "1000" : "500"
      apply_method = "immediate"
    }
  ]
}

locals {
  is_prod    = var.environment == "prod"
  is_staging = var.environment == "staging"
}
