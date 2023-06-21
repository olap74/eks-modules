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

variable "replicas" {
  description = "number of replicas for external-dns"
  type        = number
  default     = 3
}

variable "extra_domain_filters" {
  description = "domain names to include in the external-dns domain filters argument"
  type        = list(string)
  default     = []
}

variable "kubeconfig" {
  description = "Kubeconfig data"
  type        = string
}

variable "env_metadata" {
  description = "Metadata tags"
  type        = map(string)
}

variable "domains" {
    description = "Public and root domain names"
    type        = map(string)
}

variable "zones" {
    description = "Public and root zone IDs"
    type        = map(string)
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "Cluster OIDC issuer url"
  type        = string
}

variable "govcloud_comm_profile" {
  type = string
  default = null
}

variable "govcloud_comm_region" {
  type = string
  default = null
}

variable "zones_cache_duration" {
  default = "1h"
}

variable "aws_batch_change_interval" {
  default = "10s"
}

variable "enable_metrics" {
  default = "true"
}
