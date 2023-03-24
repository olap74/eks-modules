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

variable "ami_type" {
  description = "AMI Type"
  type        = string
  default     = "AL2_x86_64"
}

variable "azs" {
  description = "list of availability zones used to filter subnets"
  type        = list(string)
}

variable "bootstrap_extra_args" {
  description = "extra args to pass to eks bootstrap script"
  type        = string
  default     = ""
}

variable "capacity_type" {
  description = "node capacity type, ON_DEMAND or SPOT, defaults to ON_DEMAND"
  type        = string
  default     = "ON_DEMAND"
}

variable "cluster_version" {
  description = "kubernetes version, defaults to cluster version"
  type        = string
  default     = null
}

variable "desired_size" {
  description = "number of initial instances"
  type        = number
  default     = null
}

variable "eks_worker_ami_name" {
  description = "EKS Worker AMI name template"
  type        = string
  default     = null
}

variable "eks_worker_ami_owner" {
  description = "EKS worker AMI owner"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_types" {
  description = "Set of instance types associated with node group, defaults to [\"t3.medium\"]"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "kubelet_extra_args" {
  description = "extra kubelet args to pass to worker nodes"
  type        = string
  default     = ""
}

variable "labels" {
  description = "additional node labels"
  type        = map(string)
  default     = {}
}

variable "release_version" {
  description = "ami version"
  type        = string
  default     = null
}

variable "role_alias" {
  description = "worker role alias"
  type        = string
  default     = "default"
}

variable "subnet_classes" {
  description = "list of subnet classes used to filter subnets"
  type        = list(string)
  default     = ["node"]
}

variable "max_size" {
  description = "maximum number of instances"
  type        = number
  default     = 5
}

variable "min_size" {
  description = "minimum number of instances"
  type        = number
  default     = 1
}

variable "volume_size" {
  description = "size of the root volume in gigabytes"
  type        = number
  default     = 100
}

variable "session_name" {
  description = "aws iam role session name"
  type        = string
  default     = null
}

variable "tags" {
  description = "additional aws resource tags"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "taints to apply to the node"
  type        = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default     = []
}

variable "team" {
  description = "Team name"
  type        = string
  default     = "support"
}

variable "user_data" {
  description = "additional user_data for node group"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
    description = "Environment VPC ID"
    type        = string
    default     = null
}

variable "cluster_cert_data" {
  description = "EKS Certificate authority"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API endpoint"
  type        = string
}

variable "env_metadata" {
  description = "Metadata tags"
  type        = map(string)
}

variable "worker_roles" {
  description = "Worker IAM roles"
  type        = map(map(string))
}

variable "key_pair_name" {
  description = "SSH Key pair name"
  type        = string
}

variable "worker_sg" {
  description = "EKS worker security group"
  type        = string
}

variable "node_group_prefix" {
  description = "Node group type prefix"
  type        = string
}

variable "cluster_sg" {
  description = "Cluster primary security group"
  type        =  string
}

variable "node_subnet_ids" {
  description = "Node subnets"
  type        = list(string)
}
