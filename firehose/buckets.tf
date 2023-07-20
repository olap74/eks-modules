resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "main_block_public_access" {
  bucket = aws_s3_bucket.main.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {

  bucket = aws_s3_bucket.main.bucket

  rule {
    id = "Intelligent Tiering"
    filter {}
    transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    status = "Enabled"
  }

  rule {
    id      = "Delete objects after ${var.expire_days} days"
    enabled = true
    tags    = {}

    expiration = {
      days = var.expire_days
    }

    noncurrent_version_expiration = {
      days = var.expire_days
    }
  }  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "replica" {
  bucket = local.replica_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "replica" {
  bucket = aws_s3_bucket.replica.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "replica_block_public_access" {
  bucket = aws_s3_bucket.replica.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "replica" {

  bucket = aws_s3_bucket.replica.bucket

  rule {
    id = "Intelligent Tiering"
    filter {}
    transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_transition {
      storage_class = "INTELLIGENT_TIERING"
    }
    status = "Enabled"
  }

  rule {
    id      = "Delete objects after ${var.expire_days} days"
    enabled = true
    tags    = {}

    expiration = {
      days = var.expire_days
    }

    noncurrent_version_expiration = {
      days = var.expire_days
    }
  }  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  bucket = aws_s3_bucket.replica.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  bucket = aws_s3_bucket.replica.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "role_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "replication_policy" {

  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [ 
        aws_s3_bucket.main.arn 
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
        format("%s/*", aws_s3_bucket.main.arn)
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [ aws_s3_bucket.replica.arn, format("%s/*", aws_s3_bucket.replica.arn ) ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [ "*" ]
  }
}

resource "aws_iam_role" "replication" {
  name               = "${local.name_suffix}-kinesis-replication-role"
  assume_role_policy = data.aws_iam_policy_document.role_trust.json
}

resource "aws_iam_policy" "replication" {
  name   = "${local.name_suffix}-kinesis-replication-policy"
  policy = data.aws_iam_policy_document.replication_policy.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = module.bucket.bucket_name
  role   = aws_iam_role.replication.arn
  
  rule {
    id       = "replication_rule"
    status   = "Enabled"
    filter {}
    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
      encryption_configuration {
          replica_kms_key_id = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alias/aws/s3"
      }
    }
    source_selection_criteria {
        sse_kms_encrypted_objects {
          status = "Enabled"
        }
    }
  }
}

