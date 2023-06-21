provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
  required_providers {
    aws = {
      version = "~> 3.48"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0.0"
    }
  }
}

provider "aws" {
  alias = "resource"
  region  = local.resource_region
  profile = local.resource_profile
}
