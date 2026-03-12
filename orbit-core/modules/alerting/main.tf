locals {
  is_prod          = var.environment == "prod"
  has_alert_emails = var.alert_emails != " "
}
data "aws_caller_identity" "current" {}



# sns topic

resource "aws_sns_topic" "alarms" {
  name         = "${var.name}-${var.environment}-alarms"
  display_name = "Orbit Core Agent Alarms (${var.environment})"

  tags = {
    Name        = "${var.name}-${var.environment}-alarms"
    Environment = var.environment
  }

}
# Email subscription for SNS topic

resource "aws_sns_topic_subscription" "email" {
  count     = local.has_alert_emails ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_emails
}

# sns topic Policy
resource "aws_sns_topic_policy" "alarms_policy" {
  count = local.has_alert_emails ? 1 : 0
  arn   = aws_sns_topic.alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "sns-topic-policy-${var.name}-${var.environment}"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alarms.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# cloudWatch Log Inights Queries


resource "aws_cloudwatch_query_definition" "error_rate" {
  name         = "${var.name}/${var.environment}/error-rate"
  query_string = <<-EOT
        fields @timestamp, @message @logStream
        | filter @message like /ERROR/Exception/Traceback/
        | sort @timestamp desc
        | limit 100
    EOT
}
resource "aws_cloudwatch_query_definition" "auth_failures" {
  name         = "${var.name}/${var.environment}/auth-failures"
  query_string = <<-EOT
    fields @timestamp, @message @logStream
    | filter @message like /401|403|Unauthorized|Forbidden|authentication failed|invalid token/i
    | sort @timestamp desc
    | limit 100
    EOT
}

resource "aws_cloudwatch_query_definition" "db_connection" {
  name         = "${var.name}/${var.environment}/db-connection"
  query_string = <<-EOT
    fields @timestamp, @message @logStream
    | filter @message like /connection refused|timeout|ConnectionError|OperatonalError|psycopg/i   
    | sort @timestamp desc
    | limit 50
    EOT
}
resource "aws_cloudwatch_query_definition" "llm_errors" {
  name = "orbit/${var.environment}/llm-errors"
  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /bedrock|ThrottlingException|ModelError|ValidationException|AccessDeniedException/i
    | sort @timestamp desc
    | limit 50
  EOT
}

resource "aws_cloudwatch_query_definition" "request_summary" {
  name = "orbit/${var.environment}/request-summary"
  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /HTTP/
    | parse @message /"(?<method>\w+) (?<path>[^ ]+) HTTP/
    | stats count(*) as requests by method, path
    | sort requests desc
    | limit 20
  EOT
}

resource "aws_cloudwatch_query_definition" "resource_issues" {
  name = "orbit/${var.environment}/resource-issues"
  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /MemoryError|OutOfMemory|ResourceExhausted|killed/i
    | sort @timestamp desc
    | limit 50
  EOT
}

resource "aws_cloudwatch_query_definition" "workflow_failures" {
  name = "orbit/${var.environment}/workflow-failures"
  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /workflow.*failed|execution.*error|node.*failed/i
    | sort @timestamp desc
    | limit 50
  EOT
}