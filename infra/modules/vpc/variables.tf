variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  type    = string
  default = "sa-east-1a"
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR block allowed to SSH into the EC2 instance"
}
