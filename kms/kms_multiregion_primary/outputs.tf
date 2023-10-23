
output "kms_key" {
  value       = aws_kms_key.this
  description = "Full KMS key information"
}

output "kms_key_id" {
  value       = aws_kms_key.this.key_id
  description = "The KMS key_id"
}

output "kms_key_arn" {
  value       = aws_kms_key.this.arn
  description = "The KMS key ARN"
}

output "kms_key_alias" {
  value       = aws_kms_alias.this.name
  description = "The alias for this KMS key"
}

output "kms_key_admins" {
  value       = data.aws_iam_group.devops_admin.users[*].arn
  description = "Users authorized to administer this KMS CMK"
}
