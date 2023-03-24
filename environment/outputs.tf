output "arn" {
  description = "aws vpc arn"
  value       = var.external ? data.aws_vpc.external.0.arn : module.vpc.vpc_arn
}

output "azs" {
  description = "list of availability zones"
  value       = var.external ? sort(toset([for id in local.external_subnet_ids : data.aws_subnet.external[id].availability_zone])) : module.vpc.azs
}

# output "cert" {
#   description = "acm certificate info"
#   value       = try(var.external != true ? aws_acm_certificate.this.0 : tomap(false), {})
#   sensitive   = true
# }

output "domains" {
  description = "environment domain info"
  value = {
    root   = local.enable_kubernetes ? var.root_route53_zone : ""
    public = local.enable_kubernetes ? local.public_zone_name : ""
  }
}

output "metadata" {
  description = "workspace metadata"
  value       = local.default_tags
}

output "region" {
  description = "aws region"
  value       = var.aws_region
}

output "route_table_ids" {
  description = "map of route table ids by class"
  value       = try(var.external ? local.route_table_ids_external : local.route_table_ids, {})
}

output "subnets" {
  description = "map of subnet ids by class"
  value       = local.subnets
}

output "vpc" {
  description = "vpc info"
  value       = module.vpc
}

output "vpc_name" {
  description = "vpc info"
  value       = module.vpc.name
}

output "zones" {
  description = "route53 zone info"
  value = {
    public = local.enable_kubernetes ? aws_route53_zone.public.0.zone_id : ""
    root = data.aws_route53_zone.root.zone_id
  }
}
