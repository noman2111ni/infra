output "alarm_sns_topic_arn" {
  description = "SNS Topic ARN for alarms"
  value = aws_sns_topic.alarms.arn
}
output "alarm_sns_topic_name" {
  description = "SNS Topic Name"
  value       = aws_sns_topic.alarms.name
}