variable "aws_profile" {
  description = "AWS Profile"
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

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "Cluster OIDC issuer url"
  type        = string
}

variable "vpc_id" {
    description = "Environment VPC ID"
    type        = string
    default     = null
}

variable "env_metadata" {
  description = "Metadata tags"
  type        = map(string)
}

variable "labels" {
  description = "additional kubernetes labels"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "additional AWS tags"
  type        = map(string)
  default     = {}
}

variable "team" {
  description = "Support team name"
  type        = string
  default     = "keel"
}

variable "whitelisted_cidrs" {
  description = "Environment sepcific whitelisted CIDRs for LBs"
  type        = list(string)
  default     = []
}

variable "chart_version" {
  description = "Helm chart version"
  default = "1.4.6"  
}
