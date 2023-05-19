################################################################################
## Constants
################################################################################

locals {
  admin_arns = var.admin_arns # TODO: udpate to team/ci role

  bucket_prefixes = {
    dev = "dev"
    prod = "prod"
  }
  
  bucket_prefix = local.bucket_prefixes[var.aws_profile]

  bucket = format("%s-%s-env-configs", local.bucket_prefix, var.env_name)

  component = "kubeconfig"

  default_tags = merge(var.tags, {
    account           = var.aws_profile
    owner             = var.owner
    terraform         = true
  })
}

################################################################################
## Resources
################################################################################

# provision s3 bucket
resource "aws_s3_bucket" "this" {
  bucket = local.bucket
  acl    = "authenticated-read"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.default_tags, {
    Name = format ("kubeconfig store for %s", var.aws_profile)
  })
}

# allow admins to access kubeconfig
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket.json
  depends_on = [aws_s3_bucket.this]
}

# define bucket policy
data "aws_iam_policy_document" "bucket" {
  # allow concourse to list kubeconfigs
  statement {
    actions   = ["s3:ListBucket"]
    effect    = "Allow"
    resources = [aws_s3_bucket.this.arn]

    principals {
      type        = "AWS"
      identifiers = local.admin_arns
    }
  }

  # allow ci to manage kubeconfigs
  statement {
    actions   = ["s3:*"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = local.admin_arns
    }
  }
}

# restrict acls to private
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on = [aws_s3_bucket_policy.this]
}
