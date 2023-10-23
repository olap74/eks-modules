locals{
    tags = merge({
    terraform = "true",
    service   = "kms_multiregion",
    },
  var.tags)
}

resource "aws_kms_replica_key" "this" {
  description = "Multiregion KMS key (secondary)"
  primary_key_arn = var.primary_key_arn
  tags = local.tags
}

resource "aws_kms_alias" "this" {
  name          = var.alias
  target_key_id = aws_kms_replica_key.this.key_id
}
