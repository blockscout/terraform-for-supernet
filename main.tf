module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.18.1"
  count                = var.existed_vpc_id == "" ? 1 : 0
  name                 = var.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = local.azs
  private_subnets      = var.vpc_private_subnet_cidrs == null ? slice(local.subnets, 0, 3) : var.vpc_private_subnet_cidrs
  public_subnets       = var.vpc_public_subnet_cidrs == null ? slice(local.subnets, 3, 6) : var.vpc_public_subnet_cidrs
  database_subnets     = var.deploy_rds_db ? slice(local.subnets, 6, 8) : []
  enable_nat_gateway   = var.enabled_nat_gateway
  enable_dns_hostnames = var.enabled_dns_hostnames
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.final_tags
}

module "lb-sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb-sg"
  description         = "SG for LB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_with_cidr_blocks = [
    {
      from_port   = 4000
      to_port     = 4000
      protocol    = "tcp"
      description = "Blockscout port"
      cidr_blocks = var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block
    }
  ]
  tags = local.final_tags
}

module "lb-verifier-sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb-sg"
  description         = "SG for LB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = [var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block]
  ingress_rules       = ["http-80-tcp"]
  egress_with_cidr_blocks = [
    {
      from_port   = 8050
      to_port     = 8050
      protocol    = "tcp"
      description = "Verifier port"
      cidr_blocks = var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block
    }
  ]
  tags = local.final_tags
}

module "verifier-sg" {
  count              = var.verifier_enabled ? 1 : 0
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-application-sg"
  description        = "SG for instances of verifier"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_cidr_blocks = [
    {
      from_port   = 8050
      to_port     = 8050
      protocol    = "tcp"
      description = "Verifier port"
      cidr_blocks = var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block
      self        = true
    }
  ]
  ingress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Verifier port"
      source_security_group_id = module.lb-verifier-sg.security_group_id
    }
  ]
  tags = local.final_tags
}

module "application-sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-application-sg"
  description        = "SG for instances of application"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_cidr_blocks = [
    {
      from_port   = 4000
      to_port     = 4000
      protocol    = "tcp"
      description = "Blockscout port"
      cidr_blocks = var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block
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
  tags = local.final_tags
}

module "db-sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-db-sg"
  description        = "SG for instance of DB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
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
  tags = local.final_tags
}

module "key_pair" {
  source     = "terraform-aws-modules/key-pair/aws"
  version    = "2.0.1"
  for_each   = var.ssh_keys
  key_name   = each.key
  public_key = each.value
  tags       = local.final_tags
}

module "rds" {
  source                              = "terraform-aws-modules/rds/aws"
  version                             = "5.1.1"
  count                               = var.deploy_rds_db ? 1 : 0
  engine                              = "postgres"
  engine_version                      = "13.7"
  family                              = "postgres13"
  major_engine_version                = "13"
  instance_class                      = var.rds_instance_type
  allocated_storage                   = var.rds_allocated_storage
  max_allocated_storage               = var.rds_max_allocated_storage
  iam_database_authentication_enabled = true
  identifier                          = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-rds-db"
  db_name                             = "blockscout"
  username                            = "blockscout"
  port                                = 5432
  multi_az                            = false
  db_subnet_group_name                = module.vpc[0].database_subnet_group
  vpc_security_group_ids              = [module.db-sg.security_group_id]
  maintenance_window                  = "Mon:00:00-Mon:03:00"
  backup_window                       = "03:00-06:00"
  enabled_cloudwatch_logs_exports     = []
  create_cloudwatch_log_group         = false
  backup_retention_period             = 7
  skip_final_snapshot                 = true
  deletion_protection                 = false
  tags                                = local.final_tags
}

module "ec2_database" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.2.1"
  count                       = var.deploy_ec2_instance_db ? 1 : 0
  name                        = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-db-instance"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  key_name                    = var.ssh_key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.db-sg.security_group_id]
  subnet_id                   = var.existed_vpc_id == "" ? element(module.vpc[0].private_subnets, 0) : element(slice([for i in data.aws_subnet.this : i.id if i.map_public_ip_on_launch == false], 0, 1), 0)
  create_iam_instance_profile = true
  tags                        = local.final_tags
  iam_role_description        = "IAM role for EC2 instance ${var.vpc_name}-db-instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = templatefile(
    "${path.module}/templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/templates/docker_compose_db.tftpl",
        {
          postgres_password = var.blockscout_settings["postgres_password"]
          postgres_user     = var.blockscout_settings["postgres_user"]
        }
      )
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  )
}

module "ec2_asg_indexer" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  version                   = "v6.7.1"
  name                      = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-indexer-instance"
  min_size                  = 1
  max_size                  = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.existed_vpc_id != "" ? slice(var.existed_private_subnets_ids, 0, 1) : slice(module.vpc[0].private_subnets, 0, 1)
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 100
    }
    triggers = ["tag"]
  }
  launch_template_name        = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-indexer-launch-template"
  launch_template_description = "Launch template indexer"
  update_default_version      = true
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.ui_and_api_instance_type
  ebs_optimized               = false
  enable_monitoring           = false
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-indexer"
  iam_role_path               = "/"
  iam_role_description        = "IAM role for indexer instance"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = base64encode(templatefile(
    "${path.module}/templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/templates/docker_compose.tftpl",
        {
          postgres_password             = var.deploy_rds_db ? module.rds[0].db_instance_password : var.blockscout_settings["postgres_password"]
          postgres_user                 = var.deploy_rds_db ? module.rds[0].db_instance_username : var.blockscout_settings["postgres_user"]
          blockscout_docker_image       = var.blockscout_settings["blockscout_docker_image"]
          rpc_address                   = var.blockscout_settings["rpc_address"]
          ws_address                    = var.blockscout_settings["ws_address"]
          postgres_host                 = var.deploy_rds_db ? module.rds[0].db_instance_address : module.ec2_database[0].private_dns
          chain_id                      = var.blockscout_settings["chain_id"]
          rust_verification_service_url = var.blockscout_settings["rust_verification_service_url"]
          indexer                       = true
          api_and_ui                    = false
        }
      )
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  ))
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = false
        volume_size           = 30
        volume_type           = "gp2"
      }
    }
  ]
  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.application-sg.security_group_id]
    }
  ]
  tag_specifications = [
    {
      resource_type = "instance"
      tags          = local.final_tags
    },
    {
      resource_type = "volume"
      tags          = local.final_tags
    }
  ]
  tags = local.final_tags
}

module "ec2_asg_verifier" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  version                   = "v6.7.1"
  name                      = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-verifier-instance"
  min_size                  = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  max_size                  = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 100
    }
    triggers = ["tag"]
  }
  launch_template_name        = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-verifier-launch-template"
  launch_template_description = "Launch template verifier"
  update_default_version      = true
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.verifier_instance_type
  ebs_optimized               = false
  enable_monitoring           = false
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-verifier"
  iam_role_path               = "/"
  iam_role_description        = "IAM role for verifier instance"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = base64encode(templatefile(
    "${path.module}/templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/templates/docker_compose_verifier.tftpl",
        {
          docker_image                       = var.verifier_settings["docker_image"]
          solidity_fetcher_list_url          = var.verifier_settings["solidity_fetcher_list_url"]
          solidity_refresh_versions_schedule = var.verifier_settings["solidity_refresh_versions_schedule"]
          vyper_refresh_versions_schedule    = var.verifier_settings["vyper_refresh_versions_schedule"]
          vyper_fetcher_list_url             = var.verifier_settings["vyper_fetcher_list_url"]
          sourcify_api_url                   = var.verifier_settings["sourcify_api_url"]
        }
      )
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  ))
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = false
        volume_size           = 30
        volume_type           = "gp2"
      }
    }
  ]
  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.verifier-sg[0].security_group_id]
    }
  ]
  tag_specifications = [
    {
      resource_type = "instance"
      tags          = local.final_tags
    },
    {
      resource_type = "volume"
      tags          = local.final_tags
    }
  ]
  target_group_arns = module.alb-verifier.target_group_arns
  tags              = local.final_tags
}

module "ec2_asg_api-and-ui" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  version                   = "v6.7.1"
  name                      = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-api-and-ui-instances"
  min_size                  = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  max_size                  = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 100
    }
    triggers = ["tag"]
  }
  launch_template_name        = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-api-and-ui-launch-template"
  launch_template_description = "Launch template api-and-ui"
  update_default_version      = true
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.ui_and_api_instance_type
  ebs_optimized               = false
  enable_monitoring           = false
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-api-and-ui"
  iam_role_path               = "/"
  iam_role_description        = "IAM role for api-and-ui-instances"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = base64encode(templatefile(
    "${path.module}/templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/templates/docker_compose.tftpl",
        {
          postgres_password             = var.deploy_rds_db ? module.rds[0].db_instance_password : var.blockscout_settings["postgres_password"]
          postgres_user                 = var.deploy_rds_db ? module.rds[0].db_instance_username : var.blockscout_settings["postgres_user"]
          blockscout_docker_image       = var.blockscout_settings["blockscout_docker_image"]
          rpc_address                   = var.blockscout_settings["rpc_address"]
          ws_address                    = var.blockscout_settings["ws_address"]
          postgres_host                 = var.deploy_rds_db ? module.rds[0].db_instance_address : module.ec2_database[0].private_dns
          chain_id                      = var.blockscout_settings["chain_id"]
          rust_verification_service_url = var.verifier_enabled ? module.alb-verifier.lb_dns_name : var.blockscout_settings["rust_verification_service_url"]
          indexer                       = false
          api_and_ui                    = true
        }
      )
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  ))
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = false
        volume_size           = 30
        volume_type           = "gp2"
      }
    }
  ]
  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.application-sg.security_group_id]
    }
  ]
  tag_specifications = [
    {
      resource_type = "instance"
      tags          = local.final_tags
    },
    {
      resource_type = "volume"
      tags          = local.final_tags
    }
  ]
  target_group_arns = module.alb.target_group_arns
  tags              = local.final_tags
}

module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.2.1"
  name               = "supernet"
  load_balancer_type = "application"
  vpc_id             = var.existed_vpc_id != "" ? var.existed_vpc_id : module.vpc[0].vpc_id
  subnets            = var.existed_vpc_id != "" ? var.existed_public_subnets_ids : module.vpc[0].public_subnets
  security_groups    = [module.lb-sg.security_group_id]
  target_groups = [
    {
      name_prefix      = "apiui-"
      backend_protocol = "HTTP"
      backend_port     = 4000
      target_type      = "instance"
    }
  ]
  http_tcp_listeners = var.ssl_certificate_arn != "" ? [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }] : [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "forward"
      redirect    = {}
  }]
  https_listeners = var.ssl_certificate_arn != "" ? [
    {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = var.ssl_certificate_arn
    }
  ] : []
  tags = local.final_tags
}

module "alb-verifier" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.2.1"
  name               = "verifier"
  internal           = true
  load_balancer_type = "application"
  vpc_id             = var.existed_vpc_id != "" ? var.existed_vpc_id : module.vpc[0].vpc_id
  subnets            = var.existed_vpc_id != "" ? var.existed_public_subnets_ids : module.vpc[0].public_subnets
  security_groups    = [module.lb-verifier-sg.security_group_id]
  target_groups = [
    {
      name_prefix      = "verif-"
      backend_protocol = "HTTP"
      backend_port     = 8050
      target_type      = "instance"
    }
  ]
  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "forward"
      redirect    = {}
    }
  ]
  tags = local.final_tags
}