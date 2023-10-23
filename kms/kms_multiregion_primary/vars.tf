variable "aws_region" {
  description = "AWS Region"
}

variable "aws_profile" {
  description = "AWS Profile"
}

variable "remote_state_bucket" {}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "alias" {
  description = "Alias for the KMS customer managed key so we have an easier way to refer to it"
  default     = "Multiregion master key"
}

variable "primary_region_iam_roles" {
  type = list(string)
  description = "Primary regions IAM roles that will use the key"
}

variable "secondary_region_iam_roles" {
  type = list(string)
  description = "Secodary regions IAM roles that will use the key"
}

variable "admin_group" {
  description = "IAM group of users whom allowed admin access to the KMS"
  default = ""
}

