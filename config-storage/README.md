## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.35 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_iam_policy_document.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_arns"></a> [admin\_arns](#input\_admin\_arns) | ARNs of admins that can access the kubeconfig bucket | `list(string)` | `[]` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile name (dev\|prod) | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | aws region | `any` | n/a | yes |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment (EKS Cluster) name | `any` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Team that owns this component | `string` | `null` | no |
| <a name="input_remote_state_bucket"></a> [remote\_state\_bucket](#input\_remote\_state\_bucket) | Terraform remote state bucket, filled in by terragrunt | `any` | n/a | yes |
| <a name="input_source_yaml"></a> [source\_yaml](#input\_source\_yaml) | Filename in kubeconfig bucket | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output\_bucket) | kubeconfig bucket info |
