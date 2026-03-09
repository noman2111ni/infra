# Create AWS ECR Repository
resource "aws_ecr_repository" "ECS_Repository" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name        = var.name
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "ECS_Repository" {
  repository = aws_ecr_repository.ECS_Repository.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_policy} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_policy
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
