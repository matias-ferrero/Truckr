locals {
  // Pick the repository object from whichever side of the `create` flag is live.
  repository = var.create ? aws_ecr_repository.backend[0] : data.aws_ecr_repository.backend[0]
}

output "repository_url" {
  value = local.repository.repository_url
}

output "registry_id" {
  value = local.repository.registry_id
}

output "repository_arn" {
  value = local.repository.arn
}
