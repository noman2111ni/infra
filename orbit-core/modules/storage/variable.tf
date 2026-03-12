variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "use_existing_assets_bucket" {
  description = "Use existing assets bucket"
  type        = bool
  default     = false
}

variable "use_existing_audit_bucket" {
  description = "Use existing audit bucket"
  type        = bool
  default     = false
}

variable "use_existing_rag_bucket" {
  description = "Use existing RAG bucket"
  type        = bool
  default     = false
}

variable "use_existing_datalake_bucket" {
  description = "Use existing datalake bucket"
  type        = bool
  default     = false
}