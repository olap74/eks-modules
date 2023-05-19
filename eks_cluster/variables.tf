variable "aws_profile" {
  description = "AWS profile name"
}

variable "aws_region" {
  description = "AWS region name"
}

variable "remote_state_bucket" {
  description = "Terraform remote state bucket, filled in by terragrunt"
}

variable "cluster_admins" {
  description = "List of non default cluster admin arns"
  type        = list(string)
  default     = []
}

variable "cluster_enabled_log_types" {
  description = "List of enabled log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS private API server endpoint, when public access is disabled"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = true # change this to internal after we have vpn deployed
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = []
}

variable "cluster_log_retention_in_days" {
  description = "number of days to retain log events"
  type        = number
  default     = 90
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.23"
}

variable "enable_default_node_groups" {
  description = "boolean flag to enable default node groups"
  type        = bool
  default     = true
}

variable "enable_irsa" {
  description = "enable openid connect provider for eks cluster"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubeconfig_aws_authenticator_command" {
  description = "Command to use to fetch AWS EKS credentials."
  type        = string
  default     = "aws"
}

variable "kubeconfig_aws_authenticator_additional_args" {
  description = "Any additional arguments to pass to the authenticator such as the role to assume. e.g. [\"-r\", \"MyEksRole\"]."
  type        = list(string)
  default     = []
}

variable "kubeconfig_aws_authenticator_command_args" {
  description = "Default arguments passed to the authenticator command. Defaults to [token -i $cluster_name]."
  type        = list(string)
  default     = []
}

variable "kubeconfig_aws_authenticator_env_variables" {
  description = "Environment variables that should be used when executing the authenticator. e.g. { AWS_PROFILE = \"eks\"}."
  type        = map(string)
  default     = {}
}

variable "kubeconfig_name" {
  description = "override entries in generated kubeconfig"
  type        = string
  default     = null
}

variable "kubeconfig_write" {
  description = "write cluster kubeconfig to local filesystem"
  type        = bool
  default     = true
}

variable "kubeconfig_write_path" {
  description = "Where to save the Kubectl config file (if `kubeconfig_write = true`). Should end in a forward slash `/` ."
  type        = string
  default     = null
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "node_subnet_classes" {
  description = "List of subnet classes used for cluster node placement"
  type        = list(string)
  default     = ["node"]
}

variable "session_name" {
  description = "AWS IAM role session name"
  type        = string
  default     = null
}

variable "subnet_classes" {
  description = "List of subnet classes for use with nodes and load balancers"
  type        = list(string)
  default     = ["nodes", "private", "public"]
}

variable "team" {
  description = "Responsible Team Name"
  type        = string
  default     = "keel"
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

variable "worker_roles" {
  description = "List of worker role aliases"
  type        = list(string)
  default     = ["default"]
}

variable "env_metadata" {
  description = "Metadata from environment module"
  type        = map(string)
  default     = {}
}

variable "private_subnets_cidrs" {
  description = "Private subnet cidrs"
  type        = list(string)
  default     = []
}

variable "public_subnets_cidrs" {
  description = "Public subnet cidrs"
  type        = list(string)
  default     = []
}

variable "config_storage_bucket" {
  description = "Storage bucket data from config-storage module"
  type        = string
  default     = null
}

variable "eks_provisioner_iam_role_arn" {
  description = "Provisioner role ARN"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "EKS VPC ID"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnet IDs for nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Publis Subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Publis Subnet IDs"
  type        = list(string)
}

variable "ssh_keys_bucket" {
  description = "S3 Bucket name for SSH keys"
  type        = string
}

variable "cluster_service_bucket_suffix" {
  description = "Services bucket prefix"
  type        = string
  default     = "services"
}

variable "allowed_cidrs" {
  description = "Allowed CIDRs list"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "argocd_cidrs" {
  description = "ArgoCD cidrs"
  type        = list(any)
  default     = []
}

variable "infra_vpc_id" {
  description = "Infra vpc id"
  type        = string
}

variable "devops_group_name" {
  default = "DevOps"
}
