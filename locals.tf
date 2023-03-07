locals {
  azs          = slice(data.aws_availability_zones.current.names, 0, 3)
  subnets      = cidrsubnets(var.vpc_cidr, 8, 8, 8, 8, 8, 8, 8, 8)
  default_tags = {}
  final_tags   = merge(var.tags, local.default_tags)
  vpc_id_rule  = var.existed_vpc_id != "" ? var.existed_vpc_id : module.vpc[0].vpc_id
  subnets_rule = var.existed_vpc_id != "" ? var.existed_public_subnets_ids : module.vpc[0].public_subnets
}