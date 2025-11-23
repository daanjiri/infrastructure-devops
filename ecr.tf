resource "aws_ecr_repository" "app_repo" {
  name                 = "entrega4"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
