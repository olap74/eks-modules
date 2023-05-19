variable "admin_arns" {
  description = "ARNs of admins that can access the kubeconfig bucket"
  type        = list(string)
  default     = []
}

variable "aws_profile" {
  description = "AWS profile name (dev|prod)"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "aws region"
}

variable "remote_state_bucket" {
  description = "Terraform remote state bucket, filled in by terragrunt"
}

variable "owner" {
  description = "Team that owns this component"
  type        = string
  default     = null
}

variable "source_yaml" {
  description = "Filename in kubeconfig bucket"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Custom tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "env_name" {
  description = "Environment (EKS Cluster) name"
}
