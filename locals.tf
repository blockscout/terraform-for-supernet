locals {
  azs          = slice(data.aws_availability_zones.current.names, 0, 3)
  subnets      = cidrsubnets(var.vpc_cidr, 8, 8, 8, 8, 8, 8, 8, 8)
  default_tags = {}
  final_tags   = merge(var.tags, local.default_tags)
}