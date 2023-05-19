## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.48 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.48 |
| <a name="provider_aws.eks-provisioner"></a> [aws.eks-provisioner](#provider\_aws.eks-provisioner) | ~> 3.48 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | v17.1.0 |
| <a name="module_trusted-cidrs"></a> [trusted-cidrs](#module\_trusted-cidrs) | terraform-aws-modules/security-group/aws |  |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cluster_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster_kms_master](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_kms_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_kms_key.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.service_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_object.kubeconfig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_s3_bucket_object.node_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object) | resource |
| [aws_security_group.worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.nodeport_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ssh_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [null_resource.cluster_dependencies](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [tls_private_key.node](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_group.devops](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_group) | data source |
| [aws_iam_policy_document.cluster_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.worker_trust_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_subnet_ids.infra_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | Allowed CIDRs list | `list(string)` | n/a | yes |
| <a name="input_argocd_cidrs"></a> [argocd\_cidrs](#input\_argocd\_cidrs) | ArgoCD cidrs | `list(any)` | `[]` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile name | `any` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region name | `any` | n/a | yes |
| <a name="input_azs"></a> [azs](#input\_azs) | List of availability zones | `list(string)` | n/a | yes |
| <a name="input_cluster_admins"></a> [cluster\_admins](#input\_cluster\_admins) | List of non default cluster admin arns | `list(string)` | `[]` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | List of enabled log types | `list(string)` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the Amazon EKS private API server endpoint is enabled. | `bool` | `true` | no |
| <a name="input_cluster_endpoint_private_access_cidrs"></a> [cluster\_endpoint\_private\_access\_cidrs](#input\_cluster\_endpoint\_private\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS private API server endpoint, when public access is disabled | `list(string)` | <pre>[<br>  "10.0.0.0/8"<br>]</pre> | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled. | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint. | `list(string)` | `[]` | no |
| <a name="input_cluster_log_retention_in_days"></a> [cluster\_log\_retention\_in\_days](#input\_cluster\_log\_retention\_in\_days) | number of days to retain log events | `number` | `90` | no |
| <a name="input_cluster_service_bucket_suffix"></a> [cluster\_service\_bucket\_suffix](#input\_cluster\_service\_bucket\_suffix) | Services bucket prefix | `string` | `"services"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for the EKS cluster. | `string` | `"1.23"` | no |
| <a name="input_config_storage_bucket"></a> [config\_storage\_bucket](#input\_config\_storage\_bucket) | Storage bucket data from config-storage module | `string` | `null` | no |
| <a name="input_devops_group_name"></a> [devops\_group\_name](#input\_devops\_group\_name) | n/a | `string` | `"DevOps"` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | EKS cluster name | `string` | n/a | yes |
| <a name="input_eks_provisioner_iam_role_arn"></a> [eks\_provisioner\_iam\_role\_arn](#input\_eks\_provisioner\_iam\_role\_arn) | Provisioner role ARN | `string` | `null` | no |
| <a name="input_enable_default_node_groups"></a> [enable\_default\_node\_groups](#input\_enable\_default\_node\_groups) | boolean flag to enable default node groups | `bool` | `true` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | enable openid connect provider for eks cluster | `bool` | `true` | no |
| <a name="input_env_metadata"></a> [env\_metadata](#input\_env\_metadata) | Metadata from environment module | `map(string)` | `{}` | no |
| <a name="input_infra_vpc_id"></a> [infra\_vpc\_id](#input\_infra\_vpc\_id) | Infra vpc id | `string` | n/a | yes |
| <a name="input_kubeconfig_aws_authenticator_additional_args"></a> [kubeconfig\_aws\_authenticator\_additional\_args](#input\_kubeconfig\_aws\_authenticator\_additional\_args) | Any additional arguments to pass to the authenticator such as the role to assume. e.g. ["-r", "MyEksRole"]. | `list(string)` | `[]` | no |
| <a name="input_kubeconfig_aws_authenticator_command"></a> [kubeconfig\_aws\_authenticator\_command](#input\_kubeconfig\_aws\_authenticator\_command) | Command to use to fetch AWS EKS credentials. | `string` | `"aws"` | no |
| <a name="input_kubeconfig_aws_authenticator_command_args"></a> [kubeconfig\_aws\_authenticator\_command\_args](#input\_kubeconfig\_aws\_authenticator\_command\_args) | Default arguments passed to the authenticator command. Defaults to [token -i $cluster\_name]. | `list(string)` | `[]` | no |
| <a name="input_kubeconfig_aws_authenticator_env_variables"></a> [kubeconfig\_aws\_authenticator\_env\_variables](#input\_kubeconfig\_aws\_authenticator\_env\_variables) | Environment variables that should be used when executing the authenticator. e.g. { AWS\_PROFILE = "eks"}. | `map(string)` | `{}` | no |
| <a name="input_kubeconfig_name"></a> [kubeconfig\_name](#input\_kubeconfig\_name) | override entries in generated kubeconfig | `string` | `null` | no |
| <a name="input_kubeconfig_write"></a> [kubeconfig\_write](#input\_kubeconfig\_write) | write cluster kubeconfig to local filesystem | `bool` | `true` | no |
| <a name="input_kubeconfig_write_path"></a> [kubeconfig\_write\_path](#input\_kubeconfig\_write\_path) | Where to save the Kubectl config file (if `kubeconfig_write = true`). Should end in a forward slash `/` . | `string` | `null` | no |
| <a name="input_map_roles"></a> [map\_roles](#input\_map\_roles) | Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format. | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_map_users"></a> [map\_users](#input\_map\_users) | Additional IAM users to add to the aws-auth configmap. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_node_subnet_classes"></a> [node\_subnet\_classes](#input\_node\_subnet\_classes) | List of subnet classes used for cluster node placement | `list(string)` | <pre>[<br>  "node"<br>]</pre> | no |
| <a name="input_node_subnet_ids"></a> [node\_subnet\_ids](#input\_node\_subnet\_ids) | Subnet IDs for nodes | `list(string)` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Publis Subnet IDs | `list(string)` | n/a | yes |
| <a name="input_private_subnets_cidrs"></a> [private\_subnets\_cidrs](#input\_private\_subnets\_cidrs) | Private subnet cidrs | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Publis Subnet IDs | `list(string)` | n/a | yes |
| <a name="input_public_subnets_cidrs"></a> [public\_subnets\_cidrs](#input\_public\_subnets\_cidrs) | Public subnet cidrs | `list(string)` | `[]` | no |
| <a name="input_remote_state_bucket"></a> [remote\_state\_bucket](#input\_remote\_state\_bucket) | Terraform remote state bucket, filled in by terragrunt | `any` | n/a | yes |
| <a name="input_session_name"></a> [session\_name](#input\_session\_name) | AWS IAM role session name | `string` | `null` | no |
| <a name="input_ssh_keys_bucket"></a> [ssh\_keys\_bucket](#input\_ssh\_keys\_bucket) | S3 Bucket name for SSH keys | `string` | n/a | yes |
| <a name="input_subnet_classes"></a> [subnet\_classes](#input\_subnet\_classes) | List of subnet classes for use with nodes and load balancers | `list(string)` | <pre>[<br>  "nodes",<br>  "private",<br>  "public"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional resource tags | `map(string)` | `{}` | no |
| <a name="input_team"></a> [team](#input\_team) | Responsible Team Name | `string` | `"keel"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | VPC CIDR block | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | EKS VPC ID | `string` | n/a | yes |
| <a name="input_worker_roles"></a> [worker\_roles](#input\_worker\_roles) | List of worker role aliases | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | cluster info |
| <a name="output_key_pair"></a> [key\_pair](#output\_key\_pair) | aws key pair info |
| <a name="output_kms_key"></a> [kms\_key](#output\_kms\_key) | cluster kms key info |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | rendered cluster config |
| <a name="output_oidc_provider_arn_commercial_account"></a> [oidc\_provider\_arn\_commercial\_account](#output\_oidc\_provider\_arn\_commercial\_account) | ARN of the oidc provider in the commercial account, additionally created for EKS clusters in GovCloud |
| <a name="output_service_state_bucket"></a> [service\_state\_bucket](#output\_service\_state\_bucket) | Services state S3 bucket |
| <a name="output_worker_roles"></a> [worker\_roles](#output\_worker\_roles) | worker role info |
| <a name="output_worker_security_group"></a> [worker\_security\_group](#output\_worker\_security\_group) | worker security group info |
