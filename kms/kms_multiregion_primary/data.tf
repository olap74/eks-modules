locals {
  tags = merge({
    terraform = "true",
    service   = "kms_multiregion",
    },
  var.tags)

  primary_roles = [ for primary in var.primary_region_iam_roles : "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:role/${primary}" ]
  secondary_roles = [ for secondary in var.secondary_region_iam_roles : "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:role/${secondary}" ]
}

data "aws_caller_identity" "this" {
}

# lookup aws partition
data "aws_partition" "this" {}

data "aws_iam_group" "admin_group" {
  group_name = var.admin_group
}

data "aws_iam_policy_document" "this" {
  statement {
    # This is the root break-glass IAM policy statement for managing the KMS CMK
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:root"]
    }
    actions   = ["kms:*", ]
    resources = ["*", ]
  }

  statement {
    sid    = "Enable DevOpsAdmin to administer keys"
    effect = "Allow"

    # Originally tried to use group/DevOpsAdmin but
    #  groups are not allowed as principals, ended up using a data lookup to get all DevOpsAdmin users
    principals {
      type        = "AWS"
      identifiers = data.aws_iam_group.devops_admin.users[*].arn
    }

    actions = ["kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion", ]
    resources = ["*", ]
  }

  statement {
    sid    = "Enable use of the key for main region"
    effect = "Allow"
    principals {
      identifiers = local.primary_roles
      type        = "AWS"
    }
    actions = [
      "kms:GetPublicKey",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Enable use of the key for other regions"
    effect = "Allow"
    principals {
      identifiers = local.secondary_roles
      type        = "AWS"
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
  
  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      identifiers = concat(local.primary_roles, local.secondary_roles)
      type        = "AWS"
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    resources = ["*"]
    condition {
      test     = "Bool"
      values   = ["true"]
      variable = "kms:GrantIsForAWSResource"
    }
  }
}
