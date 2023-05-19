provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "configs"
  region  = var.config_region
  profile = var.aws_profile

  assume_role {
    role_arn     = var.eks_provisioner_iam_role_arn
    session_name = "eks-provisioner"
  }
}

provider "aws" {
  alias = "eks-provisioner"

  region  = var.aws_region
  profile = var.aws_profile

  assume_role {
    role_arn     = var.eks_provisioner_iam_role_arn
    session_name = "eks-provisioner"
  }
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0.0"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
