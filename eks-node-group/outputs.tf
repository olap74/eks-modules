output "node_group" {
  description = "eks managed node group metadata"
  value       = aws_eks_node_group.this
}
