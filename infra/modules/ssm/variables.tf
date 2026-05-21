variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "rails_master_key" {
  type      = string
  sensitive = true
}
