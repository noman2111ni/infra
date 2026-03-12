output "assets_bucket_name" {
  description = "Assets S3 Bucket Name"
  value       = var.use_existing_assets_bucket ? "orbit-assets-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.assets[0].id
}

output "assets_bucket_arn" {
  description = "Assets S3 Bucket ARN"
  value       = var.use_existing_assets_bucket ? "arn:aws:s3:::orbit-assets-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.assets[0].arn
}

output "audit_bucket_name" {
  description = "Audit S3 Bucket Name"
  value       = var.use_existing_audit_bucket ? "orbit-audit-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.audit[0].id
}

output "audit_bucket_arn" {
  description = "Audit S3 Bucket ARN"
  value       = var.use_existing_audit_bucket ? "arn:aws:s3:::orbit-audit-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.audit[0].arn
}

output "rag_bucket_name" {
  description = "RAG S3 Bucket Name"
  value       = var.use_existing_rag_bucket ? "orbit-rag-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.rag[0].id
}

output "rag_bucket_arn" {
  description = "RAG S3 Bucket ARN"
  value       = var.use_existing_rag_bucket ? "arn:aws:s3:::orbit-rag-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.rag[0].arn
}

output "datalake_bucket_name" {
  description = "Datalake S3 Bucket Name"
  value       = var.use_existing_datalake_bucket ? "orbit-datalake-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.datalake[0].id
}

output "datalake_bucket_arn" {
  description = "Datalake S3 Bucket ARN"
  value       = var.use_existing_datalake_bucket ? "arn:aws:s3:::orbit-datalake-${data.aws_caller_identity.current.account_id}-${var.region}" : aws_s3_bucket.datalake[0].arn
}