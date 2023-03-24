################################################################################
## Data Sources
################################################################################

# Custom AMI lookup
data "aws_ami" "eks_worker" {
  count       = local.custom_ami && local.custom_ami_id ? 1 : 0
  most_recent = true
  owners      = [var.eks_worker_ami_owner]
  filter {
    name   = "name"
    values = [var.eks_worker_ami_name]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


################################################################################
## References
################################################################################

locals {
  # check for additional user data
  additional_user_data = length(var.user_data) > 0

  # define cluster azs
  azs = var.azs

  # bootstrap user data when using custom ami
  bootstrap_userdata = <<CONFIG
/etc/eks/bootstrap.sh \
--b64-cluster-ca '${var.cluster_cert_data}' \
--apiserver-endpoint '${var.cluster_endpoint}' \
${var.bootstrap_extra_args} \
--kubelet-extra-args '${var.kubelet_extra_args}' \
'${local.cluster_name}'
CONFIG

  cluster_name = var.environment

  component = "eks-node-group"

  custom_ami = var.eks_worker_ami_name != null

  custom_ami_id = var.eks_worker_ami_name != null

  desired_size = var.desired_size != null ? var.desired_size : max(length(var.node_subnet_ids), var.min_size)

  # define list of unsupported availability zones
  exclude_azs = []

  labels = {
    for k, v in merge(var.labels, var.env_metadata) :
    k => v
    if max([
      for pattern in ["kubernetes\\.io/", "k8s\\.io/", "eks\\.amazonaws\\.com/"] :
      length(regexall(pattern, k))
    ]...) == 0
  }

  node_group_base_name = var.environment
  node_group_name      = format("%s-%s-%s", var.environment, var.node_group_prefix, random_pet.this.id)

  node_role_arn = var.worker_roles[var.role_alias].arn

  tags = merge(var.tags, var.env_metadata)
}

################################################################################
## Resources
################################################################################

# provision eks node group
resource "aws_eks_node_group" "this" {
  cluster_name    = local.cluster_name
  labels          = local.labels
  node_group_name = local.node_group_name
  node_role_arn   = local.node_role_arn
  subnet_ids      = var.node_subnet_ids
  tags            = local.tags

  ami_type        = var.ami_type
  capacity_type   = var.capacity_type
  instance_types  = var.instance_types
  release_version = var.release_version
  //version         = var.cluster_version

  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  scaling_config {
    desired_size = local.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# generate random group alias when replacement needed
resource "random_pet" "this" {
  length    = 1
  separator = "-"

  keepers = {
    ami_type        = var.ami_type
    capacity_type   = var.capacity_type
    instance_types  = join(",", sort(var.instance_types))
    cluster_name    = var.environment
    node_group_name = var.environment
    node_role_arn   = var.worker_roles[var.role_alias].arn
    subnet_ids      = join(",", sort(var.node_subnet_ids))
    version         = var.cluster_version
    ami_name        = var.eks_worker_ami_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# provision eks node group launch template
resource "aws_launch_template" "this" {
  name        = format("%s-%s-%s", local.component, var.environment, var.node_group_prefix)
  description = "launch template for eks node group (${local.node_group_base_name})"
  key_name    = var.key_pair_name
  tags        = local.tags

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      encrypted   = true
      volume_size = var.volume_size
    }
  }

  # set custom ami
  image_id = local.custom_ami && local.custom_ami_id ? data.aws_ami.eks_worker.0.id : null

  # additional user_data to add
  user_data = local.additional_user_data || local.custom_ami ? data.cloudinit_config.this[0].rendered : ""

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      Name = format("eks-node-group (%s)", local.node_group_base_name)
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags, {
      Name = format("eks-node-group (%s)", local.node_group_base_name)
    })
  }

  vpc_security_group_ids = [
    var.cluster_sg,
    var.worker_sg
  ]
}

# cloudinit config for custom userdata
data "cloudinit_config" "this" {
  count         = local.additional_user_data || local.custom_ami && local.custom_ami_id ? 1 : 0
  gzip          = false
  base64_encode = true
  boundary      = "//"

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/userdata.sh.tpl",
      {
        pre_userdata       = lookup(var.user_data, "pre_userdata", "")
        bootstrap_userdata = local.custom_ami ? local.bootstrap_userdata : ""
      }
    )
  }
}

# modify asg to include tags
data "aws_autoscaling_group" "this" {
  name = aws_eks_node_group.this.resources.0.autoscaling_groups.0.name
}

data "aws_arn" "this" {
  arn = data.aws_autoscaling_group.this.arn
}

resource "null_resource" "asg-modifications-nodes" {
  triggers = {
    "asg"    = data.aws_autoscaling_group.this.arn
    "labels" = jsonencode(aws_eks_node_group.this.labels)
    "taints" = jsonencode(aws_eks_node_group.this.taint)
  }

  provisioner "local-exec" {
    command = <<EOF

    aws autoscaling create-or-update-tags --profile ${var.aws_profile} --region ${data.aws_arn.this.region} --tags '${aws_eks_node_group.this.labels == null ? "[]" : jsonencode([for k, v in aws_eks_node_group.this.labels : {
    "ResourceId" : data.aws_autoscaling_group.this.name
    "ResourceType" : "auto-scaling-group",
    "Key" : "k8s.io/cluster-autoscaler/node-template/label/${k}",
    "Value" : v,
    "PropagateAtLaunch" : true
    }])}'
    aws autoscaling create-or-update-tags --profile ${var.aws_profile} --region ${data.aws_arn.this.region} --tags '${aws_eks_node_group.this.taint == null ? "[]" : jsonencode([for i in aws_eks_node_group.this.taint : {
    "ResourceId" : data.aws_autoscaling_group.this.name
    "ResourceType" : "auto-scaling-group",
    "Key" : "k8s.io/cluster-autoscaler/node-template/taint/${i.key}",
    "Value" : "${i.value}:${replace(title(replace(lower(i.effect), "_", " ")), " ", "")}",
    "PropagateAtLaunch" : true
}])}'
    EOF
}
}
