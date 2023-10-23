
output "kms_key" {
  value       = aws_kms_replica_key.this
  description = "Full KMS key information"
}

output "kms_key_id" {
  value       = aws_kms_replica_key.this.key_id
  description = "The KMS key_id"
}

output "kms_key_arn" {
  value       = aws_kms_replica_key.this.arn
  description = "The KMS key ARN"
}
