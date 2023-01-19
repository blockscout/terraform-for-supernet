locals {
  azs                 = slice(data.aws_availability_zones.current.names, 0, 3)
  subnets             = cidrsubnets(var.vpc_cidr, 8, 8, 8, 8, 8, 8, 8, 8)
  default_tags        = {}
  final_tags          = merge(var.tags, local.default_tags)
  private_subnets_map = { for k, v in(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets) : k => { subnet_id = v } }
}