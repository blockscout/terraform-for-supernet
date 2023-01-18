module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.18.1"
  count                = var.create_new_vpc == true ? 1 : 0
  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = local.azs
  private_subnets      = var.vpc_private_subnet_cidrs == null ? slice(local.subnets, 0, 3) : var.vpc_private_subnet_cidrs
  public_subnets       = var.vpc_public_subnet_cidrs == null ? slice(local.subnets, 3, 6) : var.vpc_public_subnet_cidrs
  enable_nat_gateway   = var.enabled_nat_gateway
  enable_dns_hostnames = var.enabled_dns_hostnames
  tags                 = local.final_tags
}

module "lb-sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb-sg"
  description         = "SG for LB"
  vpc_id              = var.create_new_vpc == true ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_with_cidr_blocks = [
    {
      from_port   = 4000
      to_port     = 4000
      protocol    = "tcp"
      description = "Blockscout port"
      cidr_blocks = var.create_new_vpc == true ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block
    }
  ]
}

module "application-sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-application-sg"
  description        = "SG for instances of application"
  vpc_id             = var.create_new_vpc == true ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_cidr_blocks = [
    {
      from_port   = 4000
      to_port     = 4000
      protocol    = "tcp"
      description = "Blockscout port"
      cidr_blocks = var.create_new_vpc == true ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block
      self        = true
    }
  ]
  ingress_with_source_security_group_id = [
    {
      from_port                = 4000
      to_port                  = 4000
      protocol                 = "tcp"
      description              = "Blockscout port"
      source_security_group_id = module.lb-sg.security_group_id
    }
  ]
}

module "db-sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-db-sg"
  description        = "SG for instance of DB"
  vpc_id             = var.create_new_vpc == true ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Postgresql port"
      source_security_group_id = module.application-sg.security_group_id
    }
  ]
}

module "key_pair" {
  source     = "terraform-aws-modules/key-pair/aws"
  version    = "2.0.1"
  for_each   = var.ssh_keys
  key_name   = each.key
  public_key = each.value
}

module "ec2_database" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.2.1"
  count                       = var.ec2_instance_db ? 1 : 0
  name                        = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-db-instance"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  key_name                    = var.ssh_key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.db-sg.security_group_id]
  subnet_id                   = var.create_new_vpc ? element(module.vpc[0].private_subnets, 0) : element(slice([for i in data.aws_subnet.this : i.id if i.map_public_ip_on_launch == false], 0, 1), 0)
  create_iam_instance_profile = true
  tags                        = local.final_tags
  iam_role_description        = "IAM role for EC2 instance ${var.vpc_name}-db-instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = templatefile(
    "${path.module}/templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/templates/docker_compose_db.tftpl",
        {
          postgres_password = var.docker_compose_values["postgres_password"]
          postgres_user     = var.docker_compose_values["postgres_user"]
        }
      )
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  )
}

module "ec2_indexer" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.2.1"
  count                       = var.ec2_instance_db ? 1 : 0
  name                        = "${var.vpc_name}-indexer-instance"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  key_name                    = var.ssh_key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.application-sg.security_group_id]
  subnet_id                   = var.create_new_vpc ? element(module.vpc[0].private_subnets, 0) : element(slice([for i in data.aws_subnet.this : i.id if i.map_public_ip_on_launch == false], 0, 1), 0)
  create_iam_instance_profile = true
  tags                        = local.final_tags
  iam_role_description        = "IAM role for EC2 instance ${var.vpc_name}-indexer-instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = templatefile(
    "${path.module}/templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/templates/docker_compose.tftpl",
        {
          postgres_password             = var.docker_compose_values["postgres_password"]
          postgres_user                 = var.docker_compose_values["postgres_user"]
          blockscout_docker_image       = var.docker_compose_values["blockscout_docker_image"]
          rpc_address                   = var.docker_compose_values["rpc_address"]
          postgres_host                 = var.deploy_rds ? var.docker_compose_values["postgres_host"] : module.ec2_database[0].private_dns
          chain_id                      = var.docker_compose_values["chain_id"]
          rust_verification_service_url = var.docker_compose_values["rust_verification_service_url"]
          db                            = false
          indexer                       = true
          api_and_ui                    = false
        }
      )
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  )
}

module "ec2_api_and_ui" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.2.1"
  for_each                    = local.private_subnets_map
  name                        = "${var.vpc_name}-api-and-ui-instance"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  key_name                    = var.ssh_key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.application-sg.security_group_id]
  subnet_id                   = each.value.subnet_id
  create_iam_instance_profile = true
  tags                        = local.final_tags
  iam_role_description        = "IAM role for EC2 instance ${var.vpc_name}-api-and-ui-instance"
  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = templatefile(
    "${path.module}/templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/templates/docker_compose.tftpl",
        {
          postgres_password             = var.docker_compose_values["postgres_password"]
          postgres_user                 = var.docker_compose_values["postgres_user"]
          blockscout_docker_image       = var.docker_compose_values["blockscout_docker_image"]
          rpc_address                   = var.docker_compose_values["rpc_address"]
          postgres_host                 = var.deploy_rds ? var.docker_compose_values["postgres_host"] : module.ec2_database[0].private_dns
          chain_id                      = var.docker_compose_values["chain_id"]
          rust_verification_service_url = var.docker_compose_values["rust_verification_service_url"]
          db                            = false
          indexer                       = false
          api_and_ui                    = true
        }
      )
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  )
}

module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.2.1"
  name               = "supernet-test"
  load_balancer_type = "application"
  vpc_id             = var.existed_vpc_id != "" ? var.existed_vpc_id : module.vpc[0].vpc_id
  subnets            = var.existed_vpc_id != "" ? var.existed_public_subnets_ids : module.vpc[0].public_subnets
  security_groups    = [module.lb-sg.security_group_id]
  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        for k, v in local.private_subnets_map : k => {
          target_id = module.ec2_api_and_ui[k].id
          port      = 4000
        }
      }
    }
  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = var.ssl_certificate_arn
    }
  ]
  tags = {
    Environment = "Test"
  }
}