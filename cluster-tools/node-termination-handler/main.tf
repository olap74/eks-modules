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
  component = "aws-node-termination-handler"

  kubeconfig = yamldecode(var.kubeconfig)

  labels = {
    for k, v in merge(var.labels, var.env_metadata, {
      team = var.team
    }) : k => v if length(regexall("^[A-Za-z0-9][-A-Za-z0-9_.]*[A-Za-z0-9]$", v)) > 0
  }

  name = "${local.component}-${var.environment}"

  namespace = local.component

  tags = merge(var.tags, var.env_metadata)
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
  chart      = "aws-node-termination-handler"
  version    = "0.15.2"
  name       = format("%s-%s", substr(local.component, 0, 23), var.environment)
  namespace  = local.namespace

  values = [
    yamlencode({
      fullnameOverride             = local.name
      enableScheduledEventDraining = true
      deleteLocalData              = true
      ignoreDaemonSets             = true
      enablePrometheusServer       = true
      enableRebalanceMonitoring    = true
      prometheusServerPort         = 9092
      resources = {
        limits = {
          cpu    = "100m"
          memory = "64Mi"
        }
        requests = {
          cpu    = "10m"
          memory = "32Mi"
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.this]
}

