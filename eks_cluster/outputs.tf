output "cluster" {
  description = "cluster info"
  value       = merge(module.eks, { cluster_name = local.name })
}

output "key_pair" {
  description = "aws key pair info"
  value       = aws_key_pair.node
}

output "kms_key" {
  description = "cluster kms key info"
  value       = aws_kms_key.cluster
}

output "kubeconfig" {
  description = "rendered cluster config"
  value       = yamlencode(local.kubeconfig)
}

output "worker_roles" {
  description = "worker role info"
  value = {
    for alias in local.worker_roles : alias => {
      arn = aws_iam_role.worker[alias].arn
      id  = aws_iam_role.worker[alias].id
    }
  }
}

output "worker_security_group" {
  description = "worker security group info"
  value = {
    arn = aws_security_group.worker.arn
    id  = aws_security_group.worker.id
  }
}

output "service_state_bucket" {
  description = "Services state S3 bucket"
  value = {
    "name" = aws_s3_bucket.service_state.bucket
    "arn" = aws_s3_bucket.service_state.arn
  }
}

