variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "key_pair_name" {
  type        = string
  description = "Name of the SSH key pair in AWS"
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR allowed for SSH access (e.g. your IP: 1.2.3.4/32)"
}

variable "rails_master_key" {
  type        = string
  sensitive   = true
  description = "Contents of backend/config/master.key"
}

variable "github_org" {
  type        = string
  description = "GitHub org or user that owns the repository (e.g. tcorzo)"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (e.g. fiuba-gestion-tp)"
}
