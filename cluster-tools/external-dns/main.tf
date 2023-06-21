################################################################################
## Providers
################################################################################

# configure helm provider
provider "helm" {
  kubernetes {
    host                   = local.kubeconfig.clusters.0.cluster.server
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# configure kubernetes provider
provider "kubernetes" {
  host                   = local.kubeconfig.clusters.0.cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
  token                  = data.aws_eks_cluster_auth.this.token
}

locals {
  resource_profile = var.govcloud_comm_profile != null ? var.govcloud_comm_profile : var.aws_profile
  resource_region = var.govcloud_comm_region != null ?  var.govcloud_comm_region : var.aws_region
}


################################################################################
## Data Sources
################################################################################

# import eks cluster auth info
data "aws_eks_cluster_auth" "this" {
  name = local.kubeconfig.users.0.user.exec.args.3
}

data "aws_route53_zone" "extra_domains" {
  provider = aws.resource
  for_each = toset(var.extra_domain_filters)
  name     = each.value
}

data "aws_partition" "this" {}

################################################################################
## References
################################################################################

locals {
  component = "external-dns"

  kubeconfig = yamldecode(var.kubeconfig)

  labels = {
    for k, v in merge(var.labels, var.env_metadata, {
      team = var.team
    }) : k => v if length(regexall("^[A-Za-z0-9][-A-Za-z0-9_.]*[A-Za-z0-9]$", v)) > 0
  }

  name = "${local.component}-${var.environment}"

  namespace = local.component

  tags = merge(var.tags, var.env_metadata)

  root_zone_id = var.zones.root

  zone_id = var.zones.public

  extra_domain_zone_arns = [for zone in data.aws_route53_zone.extra_domains : "arn:${data.aws_partition.this.partition}:route53:::hostedzone/${zone.id}"]

  govcloud_external_dns_custom_args = [
    "--txt-prefix=txt-",
    "--aws-prefer-cname"
  ]

  govcloud_external_dns_custom_envs = [ 
    {
      name : "AWS_REGION"
      value : "us-east-1"
    }
  ]
}

################################################################################
## Resources
################################################################################

# provision kubernetes namespace
resource "kubernetes_namespace" "this" {
  metadata {
    labels = merge(local.labels, {
      name = local.component
    })

    name = local.component
  }
}

# provision helm chart
resource "helm_release" "this" {
  atomic    = true
  chart     = "${path.root}/chart"
  name      = local.name
  namespace = local.namespace

  values = [
    yamlencode({
      domainFilters = compact(concat([var.domains.root], [var.domains.public], var.extra_domain_filters))
      txtOwnerId    = var.environment
      customArgs    = data.aws_partition.this.partition == "aws-us-gov" ? local.govcloud_external_dns_custom_args : []
      zonesCacheDuration = var.zones_cache_duration
      AWSBatchChangeInterval = var.aws_batch_change_interval
      interval = "1h"
    
      env = data.aws_partition.this.partition == "aws-us-gov" ? local.govcloud_external_dns_custom_envs : []
      podLabels = local.labels
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
        }
        name = local.name
      }
      teamLabel    = var.team
      replicaCount = var.replicas
      serviceMonitor = {
        enabled = var.enable_metrics
      }
    })
  ]

  depends_on = [kubernetes_namespace.this]
}


##############################
## IAM
##############################

# define task role
resource "aws_iam_role" "this" {
  provider = aws.resource

  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

# define trust policy for task role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    # allow ecs to assign the role to the task on our behalf
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(var.cluster_oidc_issuer_url, "https://")}:sub"
      values = [
        "system:serviceaccount:${local.namespace}:${local.name}"
      ]
    }
  }
}

# define task policy
resource "aws_iam_policy" "this" {
  provider = aws.resource
  name   = local.name
  policy = data.aws_iam_policy_document.this.json
}

# render task policy contents
data "aws_iam_policy_document" "this" {
  # allow external-dns to access autoscaling
  statement {
    actions = [
      "route53:ChangeResourceRecordSets"
    ]

    effect = "Allow"

    resources = concat([
      "arn:aws:route53:::hostedzone/${local.zone_id}",
      "arn:aws:route53:::hostedzone/${local.root_zone_id}"
    ], local.extra_domain_zone_arns)
  }

  statement {
    actions = [
      "route53:ListResourceRecordSets",
      "route53:ListHostedZones"
    ]

    effect = "Allow"

    resources = ["*"]
  }
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "this" {
  provider = aws.resource

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

