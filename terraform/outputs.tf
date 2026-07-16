# Output the repository URL so you can easily plug it into Jenkins later
output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "The URL of the ECR repository where Jenkins will push images."
}