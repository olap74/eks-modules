# Basic environment layer creation Terraform module

## Description

This module deploys a basic layer of infrastructure such as network infrastructure, domain names, required tags, routes, etc. And it's being used during deployment a new environment or any other separated part of infrastructure as a basic module. All other modules dependent on this one
This module extends an official terraform-aws-vpc module adding customization required for a new infrastructure.

This module has many flags which changes required setting sets if particular flag has been added. In case of using this network infrastructure "enable_kubernetes" flag should be set and the module will create required set of tags required for Kubernetes cluster and other Kubernetes cluster tools such as AWS load balancer controller, cluster autoscaler, etc.

Full description of flags is in the "input" section.

Besides, the module provides a very detailed output because every output variable is a map of resources which can be used by modules dependent on this module. 

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.35 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.14.2 |

## Resources

| Name | Type |
|------|------|
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_route53_record.subdomain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route_tables.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_tables) | data source |
| [aws_subnet.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet_ids.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |
| [aws_vpc.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | aws profile | `any` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | aws region | `any` | n/a | yes |
| <a name="input_azs"></a> [azs](#input\_azs) | list of aws availability zones | `list(string)` | `[]` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | aws vpc cidr block | `string` | `null` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | boolean flag to enable dns hostnames | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | boolean flag to enable dns support | `bool` | `true` | no |
| <a name="input_enable_eks"></a> [enable\_eks](#input\_enable\_eks) | boolean flag to enable eks vpc tagging | `bool` | `false` | no |
| <a name="input_enable_external_nat_ips"></a> [enable\_external\_nat\_ips](#input\_enable\_external\_nat\_ips) | boolean flag to enable static eips for nat gateways | `bool` | `false` | no |
| <a name="input_enable_kubernetes"></a> [enable\_kubernetes](#input\_enable\_kubernetes) | boolean flag to enable provisioning of route53/acm resources required for kubernetes | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | boolean flag to enable nat gateway(s) | `bool` | `true` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name (EKS cluster name) | `any` | n/a | yes |
| <a name="input_external"></a> [external](#input\_external) | boolean flag indicating vpc created outside automation | `bool` | `false` | no |
| <a name="input_external_route_table_classes"></a> [external\_route\_table\_classes](#input\_external\_route\_table\_classes) | list of network classes to use for filtering route tables and subnets | `list(string)` | `[]` | no |
| <a name="input_external_subnet_classes"></a> [external\_subnet\_classes](#input\_external\_subnet\_classes) | list of network classes to use for filtering route tables and subnets | `list(string)` | `[]` | no |
| <a name="input_external_vpc_id"></a> [external\_vpc\_id](#input\_external\_vpc\_id) | external vpc id | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | override vpc name | `string` | `null` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | boolean flag to enable dedicated nat gateways per availability zone | `bool` | `true` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | sailpoint team name (owner reference) | `string` | `null` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | list of private subnet cidr ranges by availability zone | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | list of public subnet cidr ranges by availability zone | `list(string)` | `[]` | no |
| <a name="input_remote_state_bucket"></a> [remote\_state\_bucket](#input\_remote\_state\_bucket) | Terraform remote state bucket, filled in by terragrunt | `any` | n/a | yes |
| <a name="input_root_route53_zone"></a> [root\_route53\_zone](#input\_root\_route53\_zone) | root route53 zone to reference as data source | `string` | `null` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | boolean flag to enable shared nat gateway across all availability zones | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | custom tags to apply to environment resources | `map(string)` | `{}` | no |
| <a name="input_zone_names"></a> [zone\_names](#input\_zone\_names) | map of zone name overrides by zone alias | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | aws vpc arn |
| <a name="output_azs"></a> [azs](#output\_azs) | list of availability zones |
| <a name="output_domains"></a> [domains](#output\_domains) | environment domain info |
| <a name="output_metadata"></a> [metadata](#output\_metadata) | workspace metadata |
| <a name="output_region"></a> [region](#output\_region) | aws region |
| <a name="output_route_table_ids"></a> [route\_table\_ids](#output\_route\_table\_ids) | map of route table ids by class |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | map of subnet ids by class |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | vpc info |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | vpc info |
| <a name="output_zones"></a> [zones](#output\_zones) | route53 zone info |
