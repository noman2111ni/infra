variable "name" {
  description = "ECR Repository name"
  type        = string
}

variable "environment" {
  description = "Environment test"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Scan image on push"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "Number of images to keep"
  type        = number
  default     = 10
}