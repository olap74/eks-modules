variable "aws_profile" {
  description = "aws profile"
}

variable "aws_region" {
  description = "aws region"
}

variable "remote_state_bucket" {
  description = "Terraform remote state bucket, filled in by terragrunt"
}

variable "env_name" {
  description = "Environment name (EKS cluster name)"
}

variable "azs" {
  description = "list of aws availability zones"
  type        = list(string)
  default     = []
}

variable "cidr" {
  description = "aws vpc cidr block"
  type        = string
  default     = null
}

variable "enable_dns_hostnames" {
  description = "boolean flag to enable dns hostnames"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "boolean flag to enable dns support"
  type        = bool
  default     = true
}

variable "enable_eks" {
  description = "boolean flag to enable eks vpc tagging"
  type        = bool
  default     = false
}

variable "enable_external_nat_ips" {
  description = "boolean flag to enable static eips for nat gateways"
  type        = bool
  default     = false
}

variable "enable_kubernetes" {
  description = "boolean flag to enable provisioning of route53/acm resources required for kubernetes"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "boolean flag to enable nat gateway(s)"
  type        = bool
  default     = true
}

variable "external" {
  description = "boolean flag indicating vpc created outside automation"
  type        = bool
  default     = false
}

variable "external_route_table_classes" {
  description = "list of network classes to use for filtering route tables and subnets"
  type        = list(string)
  default     = []
}

variable "external_subnet_classes" {
  description = "list of network classes to use for filtering route tables and subnets"
  type        = list(string)
  default     = []
}

variable "external_vpc_id" {
  description = "external vpc id"
  type        = string
  default     = null
}

variable "name" {
  description = "override vpc name"
  type        = string
  default     = null
}

variable "one_nat_gateway_per_az" {
  description = "boolean flag to enable dedicated nat gateways per availability zone"
  type        = bool
  default     = true
}

variable "owner" {
  description = "responsible name (owner reference)"
  type        = string
  default     = null
}

variable "private_subnets" {
  description = "list of private subnet cidr ranges by availability zone"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "list of public subnet cidr ranges by availability zone"
  type        = list(string)
  default     = []
}

variable "root_route53_zone" {
  description = "root route53 zone to reference as data source"
  type        = string
  default     = null
}

variable "single_nat_gateway" {
  description = "boolean flag to enable shared nat gateway across all availability zones"
  type        = bool
  default     = false
}

variable "tags" {
  description = "custom tags to apply to environment resources"
  type        = map(string)
  default     = {}
}

variable "zone_names" {
  description = "map of zone name overrides by zone alias"
  type        = map(string)
  default     = {}
}
