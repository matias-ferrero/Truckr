locals {
  project = "truckr"
  env     = "staging"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  project  = local.project
  env      = local.env
  ssh_cidr = var.ssh_cidr
}

module "ecr" {
  source = "../../modules/ecr"

  project = local.project
  env     = local.env
}

module "ssm" {
  source = "../../modules/ssm"

  project          = local.project
  env              = local.env
  rails_master_key = var.rails_master_key
}

module "ec2" {
  source = "../../modules/ec2"

  project           = local.project
  env               = local.env
  subnet_id         = module.vpc.public_subnet_id
  security_group_id = module.vpc.ec2_security_group_id
  key_pair_name     = var.key_pair_name
}

module "s3_frontend" {
  source = "../../modules/s3_frontend"

  project = local.project
  env     = local.env
}

module "github_oidc" {
  source = "../../modules/github_oidc"

  project                     = local.project
  env                         = local.env
  github_org                  = var.github_org
  github_repo                 = var.github_repo
  tfstate_bucket              = "truckr-tfstate-${data.aws_caller_identity.current.account_id}"
  ecr_repository_arn          = module.ecr.repository_arn
  frontend_bucket_arn         = module.s3_frontend.bucket_arn
  cloudfront_distribution_arn = module.s3_frontend.cloudfront_distribution_arn
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "app_host" {
  value       = module.ec2.app_host
  description = "Hostname Kamal claims via Let's Encrypt — copy into backend/config/deploy.yml proxy.host + servers.web"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "frontend_bucket_name" {
  value = module.s3_frontend.bucket_name
}

output "cloudfront_domain" {
  value = module.s3_frontend.cloudfront_domain
}

output "cloudfront_distribution_id" {
  value = module.s3_frontend.cloudfront_distribution_id
}

output "github_actions_role_arn" {
  value       = module.github_oidc.role_arn
  description = "IAM role ARN for GitHub Actions — set as GHA_ROLE_ARN repo secret"
}
