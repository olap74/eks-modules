## Description

This module creates a managed node group for EKS cluster and provides the next features: 

 - Fast and graceful nodes rollout 
 - Correct node labeling
 - Ability to use custom AMI

### Fast and graceful nodes rollout

The main purpose of nodes rollout for example, is keeping cluster up to date. There is no way how to update Linux Kernel version without EC2 instance restart. But the procedure provided by AWS takes long enough. This module has own node group re-creation procedure that speeds up nodes rollout at least twice.

This module has a random_pet Terraform resource. The resource generates a "random pet" name when triggered and this name is being used as a part of node group name. Any update of this resource causes node-group re-creation. Random_pet resource has custom triggers that causes its re-creation. One of the triggers is AMI name. So, if `eks_worker_ami_name` variable is updated, this causes node group re-creation. Also, node group resource has "create before destroy" policy which allows to spin up a new node group before deletion of existing and that allows Kubernetes pods to restart on new nodes. Random pet resource allows to create a new node group before deletion because node group name always differs due to random pet name. 

This feature also can be used during Kubernetes version upgrade. 

To have an absolutely graceful nodes rollout check that you have configured PodDisruptionBudget for your Kubernetes resources.

### Correct node labeling

AWS does not provide the ability to set node group labels to autoscaling group which is used by node group. As a result we can not set labels to EC2 instances which is needed for example, for cluster autoscaler. 
This module maintains this. It looks up for autoscaling group when it's created or updated and adds labels to it.

### Custom AMI usage

This module has a variable named `eks_worker_ami_name` This variable can be used for specifying a custom AMI name pattern (e.g. `my_own_eks_ami*`). If it's not set, the module uses default AWS EKS AMI (`ami_type` variable should be set).

### Other features

- Desired number of instances parameter is being ignored during update to prevent of outages because cluster autoscaler may change this parameter also. 
- Node taints can be set using `taints` variable. Format of this variable is described below. 
- The `worker_roles` parameter contains a map of EKS worker roles and looks like: 
 `worker_roles = { main_role = { arn = "arn:aws:iam:000000000000:role/role_name", id = "role_name"}}` 

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.48 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.48 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [null_resource.asg-modifications-nodes](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_ami.eks_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_arn.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/autoscaling_group) | data source |
| [cloudinit_config.this](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | AMI Type | `string` | `"AL2_x86_64"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS account | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `any` | n/a | yes |
| <a name="input_azs"></a> [azs](#input\_azs) | List of availability zones used to filter subnets | `list(string)` | n/a | yes |
| <a name="input_bootstrap_extra_args"></a> [bootstrap\_extra\_args](#input\_bootstrap\_extra\_args) | extra args to pass to eks bootstrap script | `string` | `""` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | node capacity type, ON\_DEMAND or SPOT, defaults to ON\_DEMAND | `string` | `"ON_DEMAND"` | no |
| <a name="input_cluster_cert_data"></a> [cluster\_cert\_data](#input\_cluster\_cert\_data) | EKS Certificate authority | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | EKS API endpoint | `string` | n/a | yes |
| <a name="input_cluster_sg"></a> [cluster\_sg](#input\_cluster\_sg) | Cluster primary security group | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version, defaults to cluster version | `string` | `null` | no |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Number of initial instances (ignored during update) | `number` | `null` | no |
| <a name="input_eks_worker_ami_name"></a> [eks\_worker\_ami\_name](#input\_eks\_worker\_ami\_name) | EKS Worker AMI name template | `string` | `null` | no |
| <a name="input_eks_worker_ami_owner"></a> [eks\_worker\_ami\_owner](#input\_eks\_worker\_ami\_owner) | EKS worker AMI owner | `string` | `null` | no |
| <a name="input_env_metadata"></a> [env\_metadata](#input\_env\_metadata) | Metadata tags | `map(string)` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | Set of instance types associated with node group, defaults to ["t3.medium"] | `list(string)` | <pre>[<br>  "t3.medium"<br>]</pre> | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | SSH Key pair name | `string` | n/a | yes |
| <a name="input_kubelet_extra_args"></a> [kubelet\_extra\_args](#input\_kubelet\_extra\_args) | Extra kubelet args to pass to worker nodes | `string` | `""` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional node labels | `map(string)` | `{}` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances | `number` | `5` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances | `number` | `1` | no |
| <a name="input_node_group_prefix"></a> [node\_group\_prefix](#input\_node\_group\_prefix) | Node group type prefix | `string` | n/a | yes |
| <a name="input_node_subnet_ids"></a> [node\_subnet\_ids](#input\_node\_subnet\_ids) | Node subnets | `list(string)` | n/a | yes |
| <a name="input_release_version"></a> [release\_version](#input\_release\_version) | AMI version | `string` | `null` | no |
| <a name="input_remote_state_bucket"></a> [remote\_state\_bucket](#input\_remote\_state\_bucket) | Terraform remote state bucket, filled in by terragrunt | `any` | n/a | yes |
| <a name="input_role_alias"></a> [role\_alias](#input\_role\_alias) | Worker role alias | `string` | `"default"` | no |
| <a name="input_session_name"></a> [session\_name](#input\_session\_name) | AWS IAM role session name | `string` | `null` | no |
| <a name="input_subnet_classes"></a> [subnet\_classes](#input\_subnet\_classes) | List of subnet classes used to filter subnets | `list(string)` | <pre>[<br>  "node"<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional AWS resource tags | `map(string)` | `{}` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | Taints to apply to the node | <pre>list(object({<br>    key    = string<br>    value  = string<br>    effect = string<br>  }))</pre> | `[]` | no |
| <a name="input_team"></a> [team](#input\_team) | Responsible Team name | `string` | `"support"` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Additional user\_data for node group | `map(string)` | `{}` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | Size of the root volume in gigabytes | `number` | `100` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Environment VPC ID | `string` | `null` | no |
| <a name="input_worker_roles"></a> [worker\_roles](#input\_worker\_roles) | Worker IAM roles | `map(map(string))` | n/a | yes |
| <a name="input_worker_sg"></a> [worker\_sg](#input\_worker\_sg) | EKS worker security group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node_group"></a> [node\_group](#output\_node\_group) | eks managed node group metadata |
