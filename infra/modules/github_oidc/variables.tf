variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "github_org" {
  type        = string
  description = "GitHub org or user that owns the repository (e.g. tcorzo)"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (e.g. fiuba-gestion-tp)"
}

variable "tfstate_bucket" {
  type        = string
  description = "S3 bucket name used for Terraform state (grants read/write to the GHA role)"
}

variable "ecr_repository_arn" {
  type        = string
  description = "ARN of the ECR repository (grants push access to the GHA role)"
}

variable "frontend_bucket_arn" {
  type        = string
  description = "ARN of the S3 frontend bucket (grants sync access to the GHA role)"
}

variable "cloudfront_distribution_arn" {
  type        = string
  description = "ARN of the CloudFront distribution (grants invalidation access to the GHA role)"
}
