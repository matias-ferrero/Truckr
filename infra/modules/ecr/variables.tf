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
