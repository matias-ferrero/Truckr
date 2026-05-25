variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "image_count_to_keep" {
  type    = number
  default = 5
}

variable "create" {
  type        = bool
  default     = true
  description = "When true (default), this module creates the ECR repository and lifecycle policy. Set to false in additional envs that should share the existing repo (account-scoped resource)."
}
