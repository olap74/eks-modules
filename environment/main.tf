################################################################################
## Data Sources
################################################################################

# import root domain
data "aws_route53_zone" "root" {
  name = var.root_route53_zone
}


################################################################################
## References
################################################################################

locals {
  cluster_tags = merge(local.default_tags, {
    KubernetesCluster                     = local.name
    format("kubernetes.io/cluster/%s", local.name) = var.enable_eks ? "shared" : "owned"
  })

  private_subnet_tags = {
    format ("%s-eks-private", local.name)         = "true"
  }

  cluster_tags_elb = merge(local.cluster_tags, {
    "kubernetes.io/role/elb" = "1"
  })

  cluster_tags_elb_internal = merge(local.cluster_tags, {
    "kubernetes.io/role/internal-elb" = "1"
  })

  default_tags = merge(var.tags, {
    account           = var.aws_profile
    environment       = var.env_name
    owner             = var.owner
    terraform         = "true"
  })

  enable_kubernetes = var.external ? false : var.enable_kubernetes

  external_route_table_classes = toset(var.external ? var.external_route_table_classes : [])

  external_subnet_classes = toset(var.external ? var.external_subnet_classes : [])

  external_subnet_classes_azs = {
    for class in local.external_subnet_classes :
    class => toset(distinct([for subnet_id in data.aws_subnet_ids.external[class].ids : data.aws_subnet.external[subnet_id].availability_zone]))
  }
  external_subnet_classes_azs_ids = {
    for class in local.external_subnet_classes :
    class => {
      for az in local.external_subnet_classes_azs[class] :
      az => [for id in data.aws_subnet_ids.external[class].ids : id if data.aws_subnet.external[id].availability_zone == az]
    }
  }

  external_subnet_ids = var.external ? toset(flatten([for class in local.external_subnet_classes : data.aws_subnet_ids.external[class].ids])) : []

  name = var.env_name

  public_zone_name = "${var.env_name}.${var.root_route53_zone}"

  route_table_ids = {
    private = module.vpc.private_route_table_ids
    public  = module.vpc.public_route_table_ids
  }

  route_table_ids_external = {
    for class in local.external_route_table_classes :
    class => data.aws_route_tables.external[class].ids
  }

  subnets = {
    private = module.vpc.private_subnets
    public  = module.vpc.public_subnets
  }

  subnets_external = {
    for class in local.external_subnet_classes :
    class => [for az in local.external_subnet_classes_azs[class] : local.external_subnet_classes_azs_ids[class][az].0]
  }

  vpc_id = module.vpc.vpc_id
}

################################################################################
## Resources
################################################################################

# provision vpc
module "vpc" {
  source     = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  create_vpc = var.external ? false : true
  name       = local.name
  cidr       = var.cidr

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  reuse_nat_ips       = var.enable_external_nat_ips
  external_nat_ip_ids = var.enable_external_nat_ips ? aws_eip.nat.*.id : null

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = local.default_tags

  public_route_table_tags  = merge(local.cluster_tags, { class = "public" })
  private_route_table_tags = merge(local.cluster_tags, { class = "private" })

  public_subnet_tags  = merge(local.cluster_tags_elb, { class = "public" })
  private_subnet_tags = merge(local.cluster_tags_elb_internal, { class = "private" }, local.private_subnet_tags )
}

# provision static elastic ips for nat gateway(s)
resource "aws_eip" "nat" {
  count = var.enable_external_nat_ips != true ? 0 : var.enable_nat_gateway == false ? 0 : var.single_nat_gateway ? 1 : length(var.azs)
  tags  = local.default_tags
  vpc   = true
}

##############################
## Route53
##############################

# provision public route53 zone for environment
resource "aws_route53_zone" "public" {
  count = local.enable_kubernetes ? 1 : 0
  name  = local.public_zone_name
  tags = merge(local.default_tags, {
    Name = local.public_zone_name
  })
}

# add subdomain record to main zone that delegates to child public zone
resource "aws_route53_record" "subdomain" {
  count    = local.enable_kubernetes ? 1 : 0
  zone_id  = data.aws_route53_zone.root.zone_id
  name     = local.public_zone_name
  type     = "NS"
  ttl      = "30"
  records  = aws_route53_zone.public.0.name_servers
}

##############################
## ACM
##############################

# # provision top level acm cert for public zone
# resource "aws_acm_certificate" "this" {
#   count                     = local.enable_kubernetes ? 1 : 0
#   domain_name               = aws_route53_zone.public.0.name
#   subject_alternative_names = [
#     // aws_route53_zone.public.0.name,
#     "*.${var.root_route53_zone}",
#     "*.${aws_route53_zone.public.0.name}"
#   ]
#   validation_method         = "DNS"

#   tags = merge(local.default_tags, {
#     Name = var.env_name
#   })
# }

# locals {
#   validation_records = {
#     for dvo in flatten(aws_acm_certificate.this.*.domain_validation_options) : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   validation_record = local.enable_kubernetes ? local.validation_records[element(sort(keys(local.validation_records)), 0)] : {}
# }

# # provision validation zone record
# resource "aws_route53_record" "validation" {
#   count      = local.enable_kubernetes ? 1 : 0
#   name       = local.validation_records["*.${var.root_route53_zone}"].name
#   type       = local.validation_records["*.${var.root_route53_zone}"].type
#   zone_id    = data.aws_route53_zone.root.id
#   records    = [local.validation_records["*.${var.root_route53_zone}"].record]
#   ttl        = 30
#   depends_on = [aws_route53_record.subdomain.0]
# }

# # provision validation zone record
# resource "aws_route53_record" "subdomain_validation" {
#   count      = local.enable_kubernetes ? 1 : 0
#   name       = local.validation_records["*.${local.public_zone_name}"].name
#   type       = local.validation_records["*.${local.public_zone_name}"].type
#   zone_id    = aws_route53_zone.public.0.id
#   records    = [local.validation_records["*.${local.public_zone_name}"].record]
#   ttl        = 30
#   depends_on = [aws_route53_record.subdomain.0]
# }

# # validate cert using validation zone record
# resource "aws_acm_certificate_validation" "this" {

#   count                   = local.enable_kubernetes ? 1 : 0
#   certificate_arn         = aws_acm_certificate.this.0.arn

#   # TODO: fix the validations per zone
#   validation_record_fqdns = [
#     aws_route53_record.validation.0.fqdn,
#     aws_route53_record.subdomain_validation.0.fqdn
#   ]
# }

##############################
## External VPC Data Sources
##############################

# import external vpc
data "aws_vpc" "external" {
  count = var.external ? 1 : 0
  id    = var.external_vpc_id
}

# import external route tables by class
data "aws_route_tables" "external" {
  for_each = var.external ? local.external_route_table_classes : []
  vpc_id   = data.aws_vpc.external.0.id
  tags     = { class : each.value }
}

# import subnets by class
data "aws_subnet_ids" "external" {
  for_each = var.external ? local.external_subnet_classes : []
  vpc_id   = data.aws_vpc.external.0.id

  filter {
    name   = "tag:class"
    values = [each.value]
  }
}

# import individual subnet info
data "aws_subnet" "external" {
  for_each = local.external_subnet_ids
  id       = each.value
}
