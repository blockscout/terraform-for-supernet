module "db_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-db_sg"
  description        = "Allow access to DB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Allow access from app blockscout ui"
      source_security_group_id = module.app_blockscout_ui_sg.security_group_id
    },
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Allow access from app blockscout indexer"
      source_security_group_id = module.app_blockscout_indexer_sg.security_group_id
    },
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Allow access from app stats"
      source_security_group_id = module.app_stats_sg.security_group_id
    },
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Allow access from app eth_bytecode_db"
      source_security_group_id = module.app_eth_bytecode_db_sg.security_group_id
    },
  ]
  tags = local.final_tags
}

#### Main app
module "lb_blockscout_ui_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb_blockscout_ui_sg"
  description         = "Allow requests to blockscout application, attached to AWS ALB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = 4000
      to_port                  = 4000
      protocol                 = "tcp"
      description              = "Allow access to app blockscout ui"
      source_security_group_id = module.app_blockscout_ui_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_blockscout_ui_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_blockscout_ui_sg"
  description        = "Allow access to app blockscout ui from AWS ALB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 4000
      to_port                  = 4000
      protocol                 = "tcp"
      description              = "Allow access to app blockscout ui from AWS ALB"
      source_security_group_id = module.lb_blockscout_ui_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_blockscout_indexer_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_blockscout_indexer_sg"
  description        = "Allow access to internet from app blockscout indexer"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  tags               = local.final_tags
}

### New frontend
module "lb_new_frontend_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb_new_frontend_sg"
  description         = "Allow requests to new frontend application, attached to AWS ALB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Allow access to app new frontend"
      source_security_group_id = module.app_new_frontend_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_new_frontend_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_new_frontend_sg"
  description        = "Allow access to app new frontend from AWS ALB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Allow access to app new frontend from AWS ALB"
      source_security_group_id = module.lb_new_frontend_sg.security_group_id
    }
  ]
  tags = local.final_tags
}

### Verifier
module "lb_verifier_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb_verifier_sg"
  description         = "Allow requests to verifier application, attached to AWS ALB(internal and http)"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = [var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block]
  ingress_rules       = ["http-80-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app verifier"
      source_security_group_id = module.app_verifier_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_verifier_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_verifier_sg"
  description        = "Allow access to app verifier from AWS ALB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app verifier from AWS ALB"
      source_security_group_id = module.lb_verifier_sg.security_group_id
    }
  ]
  tags = local.final_tags
}

### Visualizer
module "lb_visualizer_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb_visualizer_sg"
  description         = "Allow requests to visualizer application, attached to AWS ALB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = var.new_frontend_enabled ? ["0.0.0.0/0"] : [var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block]
  ingress_rules       = var.new_frontend_enabled ? ["https-443-tcp", "http-80-tcp"] : ["http-80-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app visualizer"
      source_security_group_id = module.app_visualizer_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_visualizer_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_visualizer_sg"
  description        = "Allow access to app visualizer from AWS ALB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app visualizer from AWS ALB"
      source_security_group_id = module.lb_visualizer_sg.security_group_id
    }
  ]
  tags = local.final_tags
}

### SIG provider
module "lb_sig_provider_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb_sig_provider_sg"
  description         = "Allow requests to sig_provider application, attached to AWS ALB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = [var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block]
  ingress_rules       = ["http-80-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app sig_provider"
      source_security_group_id = module.app_sig_provider_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_sig_provider_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_sig_provider_sg"
  description        = "Allow access to app sig_provider from AWS ALB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app sig_provider from AWS ALB"
      source_security_group_id = module.lb_sig_provider_sg.security_group_id
    }
  ]
  tags = local.final_tags
}

### Stats
module "lb_stats_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb_stats_sg"
  description         = "Allow requests to stats application, attached to AWS ALB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = var.new_frontend_enabled ? ["0.0.0.0/0"] : [var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block]
  ingress_rules       = var.new_frontend_enabled ? ["https-443-tcp", "http-80-tcp"] : ["http-80-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app stats"
      source_security_group_id = module.app_stats_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_stats_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_stats_sg"
  description        = "Allow access to app stats from AWS ALB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app stats from AWS ALB"
      source_security_group_id = module.lb_stats_sg.security_group_id
    }
  ]
  tags = local.final_tags
}

### ETH bytecode db
module "lb_eth_bytecode_db_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "4.16.0"
  name                = "${var.vpc_name}-lb_eth_bytecode_db_sg"
  description         = "Allow requests to eth_bytecode_db application, attached to AWS ALB"
  vpc_id              = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  ingress_cidr_blocks = [var.existed_vpc_id == "" ? var.vpc_cidr : data.aws_vpc.selected[0].cidr_block]
  ingress_rules       = ["http-80-tcp"]
  egress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app eth_bytecode_db"
      source_security_group_id = module.app_eth_bytecode_db_sg.security_group_id
    }
  ]
  tags = local.final_tags
}
module "app_eth_bytecode_db_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  version            = "4.16.0"
  name               = "${var.vpc_name}-app_eth_bytecode_db_sg"
  description        = "Allow access to app eth_bytecode_db from AWS ALB"
  vpc_id             = var.existed_vpc_id == "" ? module.vpc[0].vpc_id : var.existed_vpc_id
  egress_cidr_blocks = ["0.0.0.0/0"] # internet access
  egress_rules       = ["all-all"]   # internet access
  ingress_with_source_security_group_id = [
    {
      from_port                = 8050
      to_port                  = 8050
      protocol                 = "tcp"
      description              = "Allow access to app eth_bytecode_db from AWS ALB"
      source_security_group_id = module.lb_eth_bytecode_db_sg.security_group_id
    }
  ]
  tags = local.final_tags
}