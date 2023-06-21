variable "aws_profile" {
  description = "AWS account"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region"
}

variable "remote_state_bucket" {
  description = "Terraform remote state bucket"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kubeconfig" {
    description = "Kubeconfig data"
    type        = string
}

variable "coredns_version" {
  description = "coredns version"
  type        = string
  default     = "v1.8.7-eksbuild.3"
}
