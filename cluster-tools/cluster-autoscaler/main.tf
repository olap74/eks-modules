# configure default kubernetes provider
provider "helm" {
  kubernetes {
    host                   = local.kubeconfig.clusters.0.cluster.server
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

################################################################################
## Data Sources
################################################################################

# import eks cluster auth info
data "aws_eks_cluster_auth" "this" {
  name     = local.kubeconfig.users.0.user.exec.args.3
}

################################################################################
## References
################################################################################

locals {
  component = "cluster-autoscaler"

  kubeconfig = yamldecode(var.kubeconfig)

  labels = {
    for k, v in merge(var.labels, var.env_metadata, {
      team = var.team
    }) : k => v if length(regexall("^[A-Za-z0-9][-A-Za-z0-9_.]*[A-Za-z0-9]$", v)) > 0
  }

  name = "${local.component}-${var.environment}"

  namespace = coalesce(var.namespace, "kube-system")

  tags = merge(var.tags, var.env_metadata)
}

################################################################################
## Resources
################################################################################

# provision helm chart
resource "helm_release" "this" {
  atomic     = true
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  name       = local.name
  namespace  = local.namespace
  version    = "9.10.4"

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = var.environment
      }
      awsRegion = var.aws_region
      extraArgs = {
        "balance-similar-node-groups" = true
      }
      image = {
        tag = var.image_tag
      }
      nameOverride = local.name
      podLabels    = local.labels
      rbac = {
        serviceAccount = {
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
          }
          name = local.name
        }
      }
    })
  ]
}

##############################
## IAM
##############################

# define task role
resource "aws_iam_role" "this" {
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
  name   = local.name
  policy = data.aws_iam_policy_document.this.json
}

# render task policy contents
data "aws_iam_policy_document" "this" {
  # allow cluster-autoscaler to access autoscaling
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    effect = "Allow"

    resources = ["*"]
  }
}

# attach policy to role
resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
