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

################################################################################
## Data Sources
################################################################################

# import eks cluster auth info
data "aws_eks_cluster_auth" "this" {
  name     = local.kubeconfig.users.0.user.exec.args.3
}

data "aws_partition" "this" {}

################################################################################
## References
################################################################################

locals {
  component = "aws-load-balancer-controller"

  kubeconfig = yamldecode(var.kubeconfig)

  labels = {
    for k, v in merge(var.labels, var.env_metadata, {
      team = var.team
    }) : k => v if length(regexall("^[A-Za-z0-9][-A-Za-z0-9_.]*[A-Za-z0-9]$", v)) > 0
  }

  name = format("%s-%s", local.component, var.environment)

  namespace = local.component

  region = var.aws_region

  # whitelisted subnets, these are common for all environments
  base_cidrs = []

  github_hook_cidrs = []

  tags = merge(var.tags, var.env_metadata)

  # whitelisted ips
  whitelist = concat(var.whitelisted_cidrs, local.base_cidrs, local.github_hook_cidrs)

  source_account = data.aws_partition.this.partition == "aws-us-gov" ? "013241004608" : "602401143452"
}

################################################################################
## Resources
################################################################################

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
  atomic     = true
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version
  name       = format("%s-%s", substr(local.component, 0, 23), terraform.workspace)
  namespace  = local.namespace

  values = [ 
    yamlencode({
      clusterName = var.environment
      fullnameOverride = local.name
      image = {
        repository = "${local.source_account}.dkr.ecr.${local.region}.amazonaws.com/amazon/aws-load-balancer-controller"
      }
      replicaCount = "3"
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
        }
        name = local.name
      }
    })
  ]

  depends_on = [kubernetes_namespace.this]
}

# add pdbs
resource "kubernetes_pod_disruption_budget" "this" {
  metadata {
    name =      local.name
    namespace = local.namespace
  }
  spec {
    max_unavailable = "33%"
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "aws-load-balancer-controller"
      }
    }
  }

  depends_on = [kubernetes_namespace.this]
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
  # https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
  statement {
    actions = [
      "iam:CreateServiceLinkedRole",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags"
    ]
    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection"
    ]
    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:CreateSecurityGroup"
    ]
    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:CreateTags"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = ["CreateSecurityGroup"]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }

    effect = "Allow"
    resources = ["arn:${data.aws_partition.this.partition}:ec2:*:*:security-group/*"]
  }

  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }

    effect = "Allow"
    resources = ["arn:${data.aws_partition.this.partition}:ec2:*:*:security-group/*"]
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup"
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }

    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }

    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule"
    ]
    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]
  }

  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
    ]
  }

  statement {
    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup"
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }

    effect = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    effect = "Allow"
    resources = ["arn:${data.aws_partition.this.partition}:elasticloadbalancing:*:*:targetgroup/*/*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
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

##############################
## Security Group
##############################

resource "aws_security_group" "this" {
  name        = "${var.environment}-lb-whitelist"
  description = "Allow whitelisted inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "http from whitelist"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = local.whitelist
  }

  ingress {
    description      = "TLS from whitelist"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = local.whitelist
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, var.env_metadata, {
    Name = format("%s-lb-whitelist", var.environment)
  })
}
