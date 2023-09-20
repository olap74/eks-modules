variable "aws_profile" {
  description = "AWS Profile Name"
}

variable "aws_region" {
  description = "AWS Region Name"
}

variable "remote_state_bucket" {
  description = "Terraform remote state bucket"
}

variable "environment" {
  description = "Environment name (EKS cluster name)"
}

variable "oidc_fully_qualified_subjects" {
  description = "OIDC fully qualified subjects"
  type        = list(string)
}

variable "roles" {
  description = "IaM Roles"
  type        = list(map(list(string)))
}

variable "env_metadata" {
  description = "Metadata (Resource tags)"
  type        = map(string)
}

variable "cluster_oidc_issuer_url" {
  description = "Cluster OIDC issuer URL"
  type        = string
}

variable "tags" {
  description = "additional resource tags"
  type        = map(string)
  default     = {}
}

variable "oidc_subjects_with_wildcards" {
  description = "The OIDC subject using wildcards to be added to the role policy"
  type        = set(string)
  default     = []
}
