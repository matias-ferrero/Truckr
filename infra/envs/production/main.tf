locals {
  project = "truckr"
  env     = "production"
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

  # Shared ECR repository (staging creates, production references). ECR repo
  # names are account-global; both envs use the same registry and segregate
  # by image tag (`staging-<sha>`, `production-<sha>`).
  create = false
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

  # More RAM headroom for real users than staging's t3.micro.
  instance_type = "t3.small"
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

  # IAM OIDC providers are account-global per URL. Staging creates it;
  # production references the existing provider via data source.
  create_oidc_provider = false
}

# Terraform outputs → SSM Parameters so deploy workflows can resolve resource
# IDs at job start without running `terraform output` (which would need state
# access). Keys are flat under /<project>/<env>/ so the backend-deploy and
# frontend-deploy workflows can read them with a single aws ssm get-parameter.
resource "aws_ssm_parameter" "ecr_repository_url" {
  name  = "/${local.project}/${local.env}/ecr_repository_url"
  type  = "String"
  value = module.ecr.repository_url
}

resource "aws_ssm_parameter" "ec2_instance_id" {
  name  = "/${local.project}/${local.env}/ec2_instance_id"
  type  = "String"
  value = module.ec2.instance_id
}

resource "aws_ssm_parameter" "app_host" {
  name  = "/${local.project}/${local.env}/app_host"
  type  = "String"
  value = module.ec2.app_host
}

# Public backend origin baked into the SPA bundle at build time as
# VITE_API_BASE_URL. Kamal terminates TLS on :443 and forwards to the Rails
# container on :80, so no port suffix.
resource "aws_ssm_parameter" "api_base_url" {
  name  = "/${local.project}/${local.env}/api_base_url"
  type  = "String"
  value = "https://${module.ec2.app_host}"
}

# Google Maps JS API key baked into the SPA bundle at build time as
# VITE_GOOGLE_MAPS_API_KEY (AddressPicker / RadiusControl / CargoMapPreview).
# Plain String, not SecureString: Vite inlines VITE_* into client JS, so this
# key is public-by-design in the browser. Access is constrained by HTTP-referrer
# + API restrictions in the Google Cloud Console, not by keeping it secret.
resource "aws_ssm_parameter" "google_maps_api_key" {
  name  = "/${local.project}/${local.env}/google_maps_api_key"
  type  = "String"
  value = "AIzaSyDeiqlsSlKze0BR6SsdGlPGpLh_fqDb2NY"
}

resource "aws_ssm_parameter" "frontend_bucket" {
  name  = "/${local.project}/${local.env}/frontend_bucket"
  type  = "String"
  value = module.s3_frontend.bucket_name
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  name  = "/${local.project}/${local.env}/cloudfront_distribution_id"
  type  = "String"
  value = module.s3_frontend.cloudfront_distribution_id
}

# Public SPA origin baked into the Rails container so ActiveAdmin's
# impersonation flow can redirect to the right /impersonate URL per env.
resource "aws_ssm_parameter" "frontend_origin" {
  name  = "/${local.project}/${local.env}/frontend_origin"
  type  = "String"
  value = "https://${module.s3_frontend.cloudfront_domain}"
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
