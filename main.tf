module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.18.1"
  for_each             = var.new_vpcs
  name                 = each.value.name
  cidr                 = each.value.cidr
  azs                  = each.value.azs
  private_subnets      = each.value.private_subnets
  public_subnets       = each.value.public_subnets
  enable_nat_gateway   = each.value.enable_nat_gateway
  enable_dns_hostnames = each.value.enable_dns_hostnames
  tags                 = each.value.tags
}

module "sg" {
  source                   = "terraform-aws-modules/security-group/aws"
  version                  = "4.16.0"
  for_each                 = var.new_vpcs
  name                     = "for-supernet"
  description              = "SG for app"
  vpc_id                   = module.vpc[each.key].vpc_id
  egress_cidr_blocks       = ["0.0.0.0/0"]
  egress_rules             = ["all-all"]
  ingress_with_cidr_blocks = var.custom_sg_rules
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = [var.image_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "key_pair" {
  source     = "terraform-aws-modules/key-pair/aws"
  version    = "2.0.1"
  for_each   = var.ssh_keys
  key_name   = each.key
  public_key = each.value
}

data "aws_subnets" "this" {
  for_each = local.values_for_ec2
  filter {
    name   = "tag:Name"
    values = ["${each.value.vpc_name}-${each.value.access_type}-${each.value.az}"]
  }
  depends_on = [
    module.vpc
  ]
}

data "aws_subnet" "this" {
  for_each = local.values_for_ec2
  id       = element(data.aws_subnets.this[each.key].ids, 0)
  depends_on = [
    data.aws_subnets.this
  ]
}

module "ec2_instance_to_new_vpc" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.2.1"
  for_each                    = local.values_for_ec2
  name                        = each.value.name
  ami                         = each.value.ami != null ? each.value.ami : data.aws_ami.ubuntu.id
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.sg[each.value.vpc_name].security_group_id]
  subnet_id                   = element([for i in data.aws_subnet.this : i.id if i.tags.Name == "${each.value.vpc_name}-${each.value.access_type}-${each.value.az}"], 0)
  create_iam_instance_profile = each.value.create_iam_instance_profile
  tags                        = each.value.tags
  user_data                   = local.user_data
  user_data_replace_on_change = true
  depends_on = [
    data.aws_subnet.this
  ]
}

module "ec2_instances_to_existed_vpc" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.2.1"
  for_each                    = var.ec2_instances_to_existed_vpc
  name                        = each.key
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = each.value.instance_type
  key_name                    = each.value.key_name
  monitoring                  = false
  vpc_security_group_ids      = each.value.sg_id
  subnet_id                   = each.value.subnet_id
  create_iam_instance_profile = each.value.create_iam_instance_profile
  tags                        = each.value.tags
  user_data                   = local.user_data
  user_data_replace_on_change = true
}