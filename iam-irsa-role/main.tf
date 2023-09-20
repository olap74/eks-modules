################################################################################
## Data Sources
################################################################################

data "aws_caller_identity" "current" {}

# lookup aws partition
data "aws_partition" "this" {}

################################################################################
## Constants
################################################################################

locals {
  arns  = [for roles in var.roles : roles]
  roles = [for roles in var.roles : keys(roles)]
  tags  = merge(var.tags, var.env_metadata)

  template_vars = {
    account          = data.aws_caller_identity.current.account_id
    partition        = data.aws_partition.this.partition
    region           = var.aws_region
  }

  template_suffix  = ".json.tmpl"
  policy_templates = { for i in fileset(path.module, "templates/*${local.template_suffix}") : trimsuffix(basename(i), local.template_suffix) => jsonencode(jsondecode(templatefile(i, local.template_vars))) }
  policy_arns      = concat(flatten([for i in var.roles : values(i)]), [for i in aws_iam_policy.policy : i.arn])
}

################################################################################
## Resources
################################################################################

# provision eks irsa roles

data "assert_test" "policy" {
  for_each = local.policy_templates

  test  = length(each.value) <= 6144
  throw = "Generated policy document for template/${each.key}${local.template_suffix} (${length(each.value)}) exceeds limit of 6144"
}

resource "aws_iam_policy" "policy" {
  for_each = local.policy_templates

  name        = "${var.environment}-${each.key}"
  path        = "/"
  description = "policy for service ${each.key}"
  tags        = local.tags
  policy      = each.value
}

module "iam_iam-assumable-role-with-oidc" {
  for_each = toset(local.roles[0])
  source   = "./iam-assumable-role-with-oidc"
  // source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  // version = "4.2.0"

  create_role                = true
  number_of_role_policy_arns = length(local.policy_arns)
  # TODO: incorporate this inside the map, right now its subject is injected to all roles
  oidc_fully_qualified_subjects = var.oidc_fully_qualified_subjects
  oidc_subjects_with_wildcards  = var.oidc_subjects_with_wildcards
  provider_url                  = var.cluster_oidc_issuer_url
  role_name                     = "${var.environment}-${each.value}"
  role_policy_arns              = local.policy_arns
  tags                          = local.tags
}
