
resource "aws_kms_key" "this" {
  description = "CAM multiregion KMS key"
  policy = data.aws_iam_policy_document.this.json
  customer_master_key_spec = "RSA_3072"
  multi_region = true
  tags = local.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
