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

variable "primary_key_arn" {
  description = "ARN of primary multiregion Key"
  type  = string
}

variable "alias" {
  description = "Alias for the KMS customer managed key so we have an easier way to refer to it"
  default     = "multiregion-key"
}
