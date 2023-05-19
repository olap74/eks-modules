################################################################################
## Data Sources
################################################################################

# import eks cluster info
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

# import eks cluster auth info
data "aws_eks_cluster_auth" "cluster" {
  provider = aws.eks-provisioner
  name     = module.eks.cluster_id
}

# lookup aws partition
data "aws_partition" "this" {}

# lookup for user accounts in DevOpsAdmin group
data "aws_iam_group" "devops" {
  group_name = var.devops_group_name
}

# ssh-key access policy
data "aws_iam_policy_document" "ssh" {
  statement {
    sid       = "EksWorkerSshKeysBucketListAccess"
    actions   = ["s3:ListBucket"]
    effect    = "Allow"
    resources = ["arn:${local.iam_prefix}:s3:::${var.ssh_keys_bucket}"]
  }
  statement {
    sid       = "EksWorkerSshKeysBucketGetAccess"
    actions   = ["s3:GetObject"]
    effect    = "Allow"
    resources = ["arn:${local.iam_prefix}:s3:::${var.ssh_keys_bucket}/*"]
  }
}

data "aws_caller_identity" "current" {}

################################################################################
## Constants
################################################################################

locals {
  # filter out excluded availability zones
  azs = var.azs

  component = "eks-cluster"

  # generate kubeconfig name
  kubeconfig_name = var.kubeconfig_name != null ? var.kubeconfig_name : local.name

  kubeconfig_path = var.kubeconfig_write_path != null ? var.kubeconfig_write_path : "${path.root}/"

  # map roles here, we should have IAM roles per team and just add them here
  # makes it a lot easier than adding individual users
  map_roles = concat(var.map_roles, [
    for alias in local.worker_roles : {
      rolearn  = aws_iam_role.worker[alias].arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ])

  # compute cluster name
  name = var.eks_cluster_name

  subnets = sort(concat(var.private_subnet_ids, var.public_subnet_ids))

  tags = merge(var.tags, var.env_metadata)

  worker_inline_policies = [
    {
      name   = "eks_ssh_keys"
      policy = data.aws_iam_policy_document.ssh.json
    }
  ]

  worker_managed_roles = {
    AmazonEKSWorkerNodePolicy          = format("arn:%s:iam::aws:policy/AmazonEKSWorkerNodePolicy", data.aws_partition.this.partition),
    AmazonEKS_CNI_Policy               = format("arn:%s:iam::aws:policy/AmazonEKS_CNI_Policy", data.aws_partition.this.partition),
    AmazonEC2ContainerRegistryReadOnly = format("arn:%s:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", data.aws_partition.this.partition),
    CloudWatchAgentServerPolicy        = format("arn:%s:iam::aws:policy/CloudWatchAgentServerPolicy", data.aws_partition.this.partition),
  }

  worker_roles = toset(var.worker_roles)

  worker_roles_attachments_ = flatten([
    for alias in local.worker_roles : [
      for name, arn in local.worker_managed_roles : {
        alias      = alias
        name       = name
        policy_arn = arn
      }
    ]
  ])

  worker_roles_attachments = {
    for attach in local.worker_roles_attachments_ : format("%s_%s", attach.alias, attach.name) => attach
  }
  bucket_prefixes = {
    dev      = "dev"
    prod     = "prod"
  }
  services_bucket_prefix = local.bucket_prefixes[var.aws_profile]
  services_bucket_name   = format("%s-%s-%s", local.services_bucket_prefix, local.name, var.cluster_service_bucket_suffix)

  mapusers = [
    for index, x in local.users_list : {
      username = x.user_name
      userarn  = x.arn
      groups   = ["system:masters"]
    }
  ]

  access_cidrs = distinct(compact(flatten(concat(
    var.cluster_endpoint_public_access_cidrs,
    var.argocd_cidrs,
    var.allowed_cidrs
  ))))
}

################################################################################
## Resources
################################################################################

# provision eks cluster
module "eks" {
  providers = {
    aws = aws.eks-provisioner
  }
  source  = "terraform-aws-modules/eks/aws"
  version = "v17.1.0"

  cluster_name    = null_resource.cluster_dependencies.triggers.cluster_name
  cluster_version = var.cluster_version

  cluster_create_endpoint_private_access_sg_rule = true
  cluster_enabled_log_types                      = var.cluster_enabled_log_types
  cluster_endpoint_private_access                = var.cluster_endpoint_private_access
  cluster_endpoint_private_access_cidrs          = var.cluster_endpoint_private_access_cidrs
  cluster_endpoint_public_access                 = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs           = local.access_cidrs
  cluster_log_retention_in_days                  = var.cluster_log_retention_in_days
  enable_irsa                                    = var.enable_irsa

  map_roles = local.map_roles
  map_users = concat(local.mapusers, var.map_users)
  subnets = local.subnets
  tags    = local.tags
  vpc_id  = var.vpc_id

  kubeconfig_aws_authenticator_additional_args = [
    "-r", var.eks_provisioner_iam_role_arn,
  ]

  kubeconfig_aws_authenticator_env_variables = { AWS_PROFILE = var.aws_profile, AWS_REGION = var.aws_region }

  write_kubeconfig = false

  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.cluster.arn
      resources        = ["secrets"]
    }
  ]
}

# wait for cluster dependencies
resource "null_resource" "cluster_dependencies" {
  triggers = {
    cluster_name = local.name
    key_pair     = aws_key_pair.node.id
  }
}

##############################
## Worker Role
##############################

# provision worker role
resource "aws_iam_role" "worker" {
  for_each           = local.worker_roles
  name               = "${local.name}-worker-${each.value}"
  assume_role_policy = data.aws_iam_policy_document.worker_trust_policy.json
  tags               = local.tags

  dynamic "inline_policy" {
    for_each = local.worker_inline_policies
    content {
      name   = inline_policy.value["name"]
      policy = inline_policy.value["policy"]
    }
  }
}

# define worker role trust policy
data "aws_iam_policy_document" "worker_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.this.dns_suffix}"]
    }
  }
}

# attach managed eks policies to worker role
resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = local.worker_roles_attachments
  role       = aws_iam_role.worker[each.value.alias].name
  policy_arn = each.value.policy_arn
}

##############################
## SSH and NodePort Access
##############################

# provision worker security group
resource "aws_security_group" "worker" {
  name        = "${local.name}-worker"
  description = "security group for eks-node-group"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name = format("%s-worker", local.name)
  })
}

# allow ssh ingress to worker security group from private network
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  description       = "allow ssh ingress from private network"
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = ["10.0.0.0/8"]
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
}

# allow NodePort ingress to worker security group from LB networks for healthchecks
resource "aws_security_group_rule" "nodeport_ingress" {
  type              = "ingress"
  description       = "allow nodePort from LB networks to allow healthchecks"
  security_group_id = aws_security_group.worker.id
  cidr_blocks = concat(
    var.private_subnets_cidrs,
    var.public_subnets_cidrs
  )
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535
}

##############################
## KMS
##############################

# provision kms for encrypting k8s secrets
resource "aws_kms_key" "cluster" {
  description             = "KMS key for ${local.name} cluster"
  deletion_window_in_days = 10
  tags                    = local.tags
}

# create cluster kms policy
resource "aws_iam_policy" "cluster_kms" {
  name   = "${local.name}-cluster-kms"
  policy = data.aws_iam_policy_document.cluster_kms.json
}

# define cluster kms policy
data "aws_iam_policy_document" "cluster_kms" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.cluster.arn]
  }
}

# attach cluster kms policy to cluster role
resource "aws_iam_role_policy_attachment" "cluster_kms_master" {
  role       = module.eks.cluster_iam_role_name
  policy_arn = aws_iam_policy.cluster_kms.arn
}

# attach cluster kms policy to worker role
resource "aws_iam_role_policy_attachment" "cluster_kms_worker" {
  role       = module.eks.worker_iam_role_name
  policy_arn = aws_iam_policy.cluster_kms.arn
}

##############################
## Node Keys
##############################

# generate rsa key pair
resource "tls_private_key" "node" {
  algorithm = "RSA"
}

# upload to aws
resource "aws_key_pair" "node" {
  key_name   = local.name
  public_key = tls_private_key.node.public_key_openssh
}

# write key to s3
resource "aws_s3_bucket_object" "node_key" {
  acl                    = "bucket-owner-full-control"
  bucket                 = var.config_storage_bucket
  key                    = "${local.name}-node_key.json"
  content                = jsonencode(tls_private_key.node)
  content_type           = "text/plain"
  server_side_encryption = "AES256"
}

##############################
## Kubeconfig
##############################

# write kubeconfig to s3
resource "aws_s3_bucket_object" "kubeconfig" {
  provider = aws.eks-provisioner

  acl                    = "bucket-owner-full-control"
  bucket                 = var.config_storage_bucket
  key                    = "${local.name}.yaml"
  content                = yamlencode(local.kubeconfig)
  content_type           = "text/plain"
  server_side_encryption = "AES256"
}

locals {
  kubeconfig = {
    apiVersion  = "v1"
    preferences = {}
    kind        = "Config"
    clusters = [{
      name = local.kubeconfig_name
      cluster = {
        server                       = module.eks.cluster_endpoint
        "certificate-authority-data" = module.eks.cluster_certificate_authority_data
      }
    }]
    contexts = [{
      name = local.kubeconfig_name
      context = {
        cluster = local.kubeconfig_name
        user    = local.kubeconfig_name
      }
    }]
    "current-context" = local.kubeconfig_name
    users = [{
      name = local.kubeconfig_name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1alpha1"
          command    = var.kubeconfig_aws_authenticator_command
          args = concat([
            "eks", "get-token", "--cluster-name", local.name
          ], var.kubeconfig_aws_authenticator_additional_args)
          env = [
            for k, v in var.kubeconfig_aws_authenticator_env_variables : {
              name  = k
              value = v
            }
          ]
        }
      }
    }]
  }
}

resource "aws_s3_bucket" "service_state" {
  bucket = local.services_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
  
  lifecycle {
    prevent_destroy = true
  }
}

module "trusted-cidrs" {
  source = "terraform-aws-modules/security-group/aws"

  ingress_cidr_blocks     = var.allowed_cidrs
  ingress_rules           = ["https-443-tcp"]
  name                    = "allowed-cidrs"
  description             = "Security group allows access from trusted CIDR blocks"
  vpc_id                  = var.vpc_id
}

data "aws_subnet_ids" "infra_public" {
  vpc_id = var.infra_vpc_id
  tags = {
    type = "public"
  }
}
