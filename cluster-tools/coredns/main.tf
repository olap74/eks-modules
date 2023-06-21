################################################################################
## Providers
################################################################################

provider "kubectl" {
  host                   = local.kubeconfig.clusters.0.cluster.server
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
  token                  = data.aws_eks_cluster_auth.this.token
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

data "template_file" "coredns" {
  template = file("${path.module}/templates/coredns-deployment.tpl")
  vars = {
    region  = var.aws_region
    version = var.coredns_version
    source_account = local.source_account 
  }
}

data "aws_partition" "this" {}

################################################################################
## References
################################################################################

locals {
  component = "coredns"
  kubeconfig = yamldecode(var.kubeconfig)
  namespace = "kube-system"
  source_account = data.aws_partition.this.partition == "aws-us-gov" ? "013241004608" : "602401143452"
}

################################################################################
## Resources
################################################################################

# coredns
resource "kubectl_manifest" "coredns" {
  yaml_body = data.template_file.coredns.rendered
}

# add pdbs
resource "kubernetes_pod_disruption_budget" "this" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
  }
  spec {
    max_unavailable = "33%"
    selector {
      match_labels = {
        "eks.amazonaws.com/component" = "coredns"
      }
    }
  }
}
