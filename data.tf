data "aws_availability_zones" "current" {}

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

data "aws_vpc" "selected" {
  count = var.existed_vpc_id != "" ? 1 : 0
  id    = var.existed_vpc_id
}

data "aws_subnets" "selected" {
  count = var.existed_vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.existed_vpc_id]
  }
}

data "aws_subnet" "this" {
  for_each = var.existed_vpc_id != "" ? toset(data.aws_subnets.selected[0].ids) : toset([])
  id       = each.value
}
