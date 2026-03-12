data "aws_caller_identity" "current" {}

locals {
  is_prod = var.environment == "prod"
  account_id = data.aws_caller_identity.current.account_id
}

#############################################
# Assets Bucket
#############################################
resource "aws_s3_bucket" "assets" {
  count  = var.use_existing_assets_bucket ? 0 : 1
  bucket = "orbit-assets-${local.account_id}-${var.region}"

  tags = {
    Name        = "orbit-assets-${var.environment}"
    Environment = var.environment
    Purpose     = "User files and documents"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  count  = var.use_existing_assets_bucket ? 0 : 1
  bucket = aws_s3_bucket.assets[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  count  = var.use_existing_assets_bucket ? 0 : 1
  bucket = aws_s3_bucket.assets[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  count  = var.use_existing_assets_bucket ? 0 : 1
  bucket = aws_s3_bucket.assets[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  count  = var.use_existing_assets_bucket ? 0 : 1
  bucket = aws_s3_bucket.assets[0].id

  rule {
    id     = "TransitionToIA"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "CleanupIncompleteMultipartUploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "assets" {
  count  = var.use_existing_assets_bucket ? 0 : 1
  bucket = aws_s3_bucket.assets[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_policy" "assets" {
  count  = var.use_existing_assets_bucket ? 0 : 1
  bucket = aws_s3_bucket.assets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.assets[0].arn,
          "${aws_s3_bucket.assets[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

#############################################
# Audit Bucket
#############################################
resource "aws_s3_bucket" "audit" {
  count  = var.use_existing_audit_bucket ? 0 : 1
  bucket = "orbit-audit-${local.account_id}-${var.region}"

  tags = {
    Name        = "orbit-audit-${var.environment}"
    Environment = var.environment
    Purpose     = "Compliance audit logs"
  }
}

resource "aws_s3_bucket_versioning" "audit" {
  count  = var.use_existing_audit_bucket ? 0 : 1
  bucket = aws_s3_bucket.audit[0].id

  versioning_configuration {
    status = local.is_prod ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  count  = var.use_existing_audit_bucket ? 0 : 1
  bucket = aws_s3_bucket.audit[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "audit" {
  count  = var.use_existing_audit_bucket ? 0 : 1
  bucket = aws_s3_bucket.audit[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  count  = var.use_existing_audit_bucket ? 0 : 1
  bucket = aws_s3_bucket.audit[0].id

  rule {
    id     = "TransitionToGlacier"
    status = "Enabled"
    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "ExpireAfter7Years"
    status = local.is_prod ? "Enabled" : "Disabled"
    expiration {
      days = 2555
    }
  }

  rule {
    id     = "CleanupIncompleteMultipartUploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "audit" {
  count  = var.use_existing_audit_bucket ? 0 : 1
  bucket = aws_s3_bucket.audit[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit[0].arn,
          "${aws_s3_bucket.audit[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

#############################################
# RAG Bucket
#############################################
resource "aws_s3_bucket" "rag" {
  count  = var.use_existing_rag_bucket ? 0 : 1
  bucket = "orbit-rag-${local.account_id}-${var.region}"

  tags = {
    Name        = "orbit-rag-${var.environment}"
    Environment = var.environment
    Purpose     = "RAG document storage"
  }
}

resource "aws_s3_bucket_versioning" "rag" {
  count  = var.use_existing_rag_bucket ? 0 : 1
  bucket = aws_s3_bucket.rag[0].id

  versioning_configuration {
    status = local.is_prod ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rag" {
  count  = var.use_existing_rag_bucket ? 0 : 1
  bucket = aws_s3_bucket.rag[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "rag" {
  count  = var.use_existing_rag_bucket ? 0 : 1
  bucket = aws_s3_bucket.rag[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "rag" {
  count  = var.use_existing_rag_bucket ? 0 : 1
  bucket = aws_s3_bucket.rag[0].id

  rule {
    id     = "CleanupIncompleteMultipartUploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "rag" {
  count  = var.use_existing_rag_bucket ? 0 : 1
  bucket = aws_s3_bucket.rag[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_policy" "rag" {
  count  = var.use_existing_rag_bucket ? 0 : 1
  bucket = aws_s3_bucket.rag[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.rag[0].arn,
          "${aws_s3_bucket.rag[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

#############################################
# Datalake Bucket
#############################################
resource "aws_s3_bucket" "datalake" {
  count  = var.use_existing_datalake_bucket ? 0 : 1
  bucket = "orbit-datalake-${local.account_id}-${var.region}"

  tags = {
    Name        = "orbit-datalake-${var.environment}"
    Environment = var.environment
    Purpose     = "Research and analytics exports"
  }
}

resource "aws_s3_bucket_versioning" "datalake" {
  count  = var.use_existing_datalake_bucket ? 0 : 1
  bucket = aws_s3_bucket.datalake[0].id

  versioning_configuration {
    status = local.is_prod ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  count  = var.use_existing_datalake_bucket ? 0 : 1
  bucket = aws_s3_bucket.datalake[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "datalake" {
  count  = var.use_existing_datalake_bucket ? 0 : 1
  bucket = aws_s3_bucket.datalake[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  count  = var.use_existing_datalake_bucket ? 0 : 1
  bucket = aws_s3_bucket.datalake[0].id

  rule {
    id     = "TransitionToIA"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "CleanupIncompleteMultipartUploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "datalake" {
  count  = var.use_existing_datalake_bucket ? 0 : 1
  bucket = aws_s3_bucket.datalake[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.datalake[0].arn,
          "${aws_s3_bucket.datalake[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}