resource "random_string" "secret_key_base" {
  length  = 64
  special = false
}

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
  multi_az                            = var.rds_multi_az
  db_subnet_group_name                = var.existed_rds_subnet_group_name != "" ? var.existed_rds_subnet_group_name : module.vpc[0].database_subnet_group
  vpc_security_group_ids              = [module.db_sg.security_group_id]
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
  monitoring                  = false
  vpc_security_group_ids      = [module.db_sg.security_group_id]
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
      nginx_config              = ""
      path_docker_compose_files = var.path_docker_compose_files
      user                      = var.user
    }
  )
}

module "ec2_asg_indexer" {
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-indexer-instance"
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier  = var.existed_vpc_id != "" ? slice(var.existed_private_subnets_ids, 0, 1) : slice(module.vpc[0].private_subnets, 0, 1)
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-indexer-launch-template"
  target_group_arns    = []
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.indexer_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-api-and-ui"
  ## Init settings
  docker_compose_file_postfix = "_indexer"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_blockscout_indexer_sg.security_group_id
  docker_compose_config = {
    postgres_password             = var.deploy_rds_db ? module.rds[0].db_instance_password : var.blockscout_settings["postgres_password"]
    postgres_user                 = var.deploy_rds_db ? module.rds[0].db_instance_username : var.blockscout_settings["postgres_user"]
    blockscout_docker_image       = var.blockscout_settings["blockscout_docker_image"]
    rpc_address                   = var.blockscout_settings["rpc_address"]
    ws_address                    = var.blockscout_settings["ws_address"]
    postgres_host                 = var.deploy_rds_db ? module.rds[0].db_instance_address : module.ec2_database[0].private_dns
    chain_id                      = var.blockscout_settings["chain_id"]
    rust_verification_service_url = var.blockscout_settings["rust_verification_service_url"]
    secret_key_base               = random_string.secret_key_base.result
  }
  tags = local.final_tags
}

module "ec2_asg_api_and_ui" {
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-api-and-ui-instances"
  min_size             = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  max_size             = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  vpc_zone_identifier  = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-api-and-ui-launch-template"
  target_group_arns    = module.alb.target_group_arns
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.ui_and_api_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-api-and-ui"
  ## Init settings
  docker_compose_file_postfix = "_api-and-ui"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_blockscout_ui_sg.security_group_id
  docker_compose_config = {
    postgres_password             = var.deploy_rds_db ? module.rds[0].db_instance_password : var.blockscout_settings["postgres_password"]
    postgres_user                 = var.deploy_rds_db ? module.rds[0].db_instance_username : var.blockscout_settings["postgres_user"]
    blockscout_docker_image       = var.blockscout_settings["blockscout_docker_image"]
    rpc_address                   = var.blockscout_settings["rpc_address"]
    ws_address                    = var.blockscout_settings["ws_address"]
    postgres_host                 = var.deploy_rds_db ? module.rds[0].db_instance_address : module.ec2_database[0].private_dns
    chain_id                      = var.blockscout_settings["chain_id"]
    rust_verification_service_url = var.eth_bytecode_db_enabled ? module.alb_eth_bytecode_db[0].lb_dns_name : var.blockscout_settings["rust_verification_service_url"]
    secret_key_base               = random_string.secret_key_base.result
    visualizer_enabled            = var.visualizer_enabled
    visualize_sol2uml_service_url = var.visualizer_enabled ? module.alb_visualizer[0].lb_dns_name : var.blockscout_settings["visualize_sol2uml_service_url"]
    sig_provider_enabled          = var.sig_provider_enabled
    sig_provider_service_url      = var.sig_provider_enabled ? module.alb_sig_provider[0].lb_dns_name : var.blockscout_settings["sig_provider_service_url"]
    new_frontend_enabled          = var.new_frontend_enabled
  }
  nginx_config = {
    service_name        = "blockscout-api-and-ui"
    backend_port        = 4000
    new_frontend_domain = var.new_frontend_domain
  }
  tags = local.final_tags
}

module "ec2_asg_new_frontend" {
  count  = var.new_frontend_enabled ? 1 : 0
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-new-frontend"
  min_size             = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  max_size             = length(var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets)
  vpc_zone_identifier  = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-new-frontend-launch-template"
  target_group_arns    = module.alb_new_frontend[0].target_group_arns
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.new_frontend_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-new-frontend"
  ## Init settings
  docker_compose_file_postfix = "_new-frontend"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_new_frontend_sg.security_group_id
  docker_compose_config = {
    docker_image       = var.new_frontend_settings["docker_image"]
    stats_api_url      = var.new_frontend_settings["stats_api_url"] != null ? var.new_frontend_settings["stats_api_url"] : module.alb_stats[0].lb_dns_name
    rpc_address        = var.new_frontend_settings["rpc_address"]
    visualizer_api_url = var.new_frontend_settings["visualizer_api_url"] != null ? var.new_frontend_settings["visualizer_api_url"] : module.alb_visualizer[0].lb_dns_name
    backend_url        = var.new_frontend_settings["backend_url"] != null ? var.new_frontend_settings["backend_url"] : module.alb.lb_dns_name
    backend_protocol   = var.new_frontend_domain != "" && var.ssl_certificate_arn != "" ? "https" : "http"
    ws_protocol        = var.new_frontend_domain != "" && var.ssl_certificate_arn != "" ? "wss" : "ws"
  }
  tags = local.final_tags
}

module "ec2_asg_verifier" {
  count  = var.verifier_enabled ? 1 : 0
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-verifier-instance"
  min_size             = var.verifier_replicas
  max_size             = var.verifier_replicas
  vpc_zone_identifier  = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-verifier-launch-template"
  target_group_arns    = module.alb_verifier[0].target_group_arns
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.verifier_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-verifier"
  ## Init settings
  docker_compose_file_postfix = "_verifier"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_verifier_sg.security_group_id
  docker_compose_config = {
    docker_image                       = var.verifier_settings["docker_image"]
    solidity_fetcher_list_url          = var.verifier_settings["solidity_fetcher_list_url"]
    solidity_refresh_versions_schedule = var.verifier_settings["solidity_refresh_versions_schedule"]
    vyper_refresh_versions_schedule    = var.verifier_settings["vyper_refresh_versions_schedule"]
    vyper_fetcher_list_url             = var.verifier_settings["vyper_fetcher_list_url"]
    sourcify_api_url                   = var.verifier_settings["sourcify_api_url"]
  }
  nginx_config = {
    service_name        = "smart-contract-verifier"
    backend_port        = 8050
    new_frontend_domain = var.new_frontend_domain
  }
  tags = local.final_tags
}

module "ec2_asg_visualizer" {
  count  = var.visualizer_enabled ? 1 : 0
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-visualizer-instance"
  min_size             = var.visualizer_replicas
  max_size             = var.visualizer_replicas
  vpc_zone_identifier  = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-verifier-launch-template"
  target_group_arns    = module.alb_visualizer[0].target_group_arns
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.visualizer_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-verifier"
  ## Init settings
  docker_compose_file_postfix = "_visualizer"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_visualizer_sg.security_group_id
  docker_compose_config = {
    docker_image = var.visualizer_docker_image
  }
  nginx_config = {
    service_name        = "visualizer"
    backend_port        = 8050
    new_frontend_domain = var.new_frontend_domain
  }
  tags = local.final_tags
}

module "ec2_asg_sig_provider" {
  count  = var.sig_provider_enabled ? 1 : 0
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-sig-provider-instance"
  min_size             = var.sig_provider_replicas
  max_size             = var.sig_provider_replicas
  vpc_zone_identifier  = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-sig-provider-launch-template"
  target_group_arns    = module.alb_sig_provider[0].target_group_arns
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.sig_provider_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-sig-provider"
  ## Init settings
  docker_compose_file_postfix = "_sig-provider"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_sig_provider_sg.security_group_id
  docker_compose_config = {
    docker_image = var.sig_provider_docker_image
  }
  nginx_config = {
    service_name        = "sig-provider"
    backend_port        = 8050
    new_frontend_domain = var.new_frontend_domain
  }
  tags = local.final_tags
}

module "ec2_asg_stats" {
  count  = var.stats_enabled ? 1 : 0
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-stats-instance"
  min_size             = var.stats_replicas
  max_size             = var.stats_replicas
  vpc_zone_identifier  = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-stats-launch-template"
  target_group_arns    = module.alb_stats[0].target_group_arns
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.stats_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-stats"
  ## Init settings
  docker_compose_file_postfix = "_stats"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_stats_sg.security_group_id
  docker_compose_config = {
    docker_image      = var.stats_docker_image
    postgres_password = var.deploy_rds_db ? module.rds[0].db_instance_password : var.blockscout_settings["postgres_password"]
    postgres_user     = var.deploy_rds_db ? module.rds[0].db_instance_username : var.blockscout_settings["postgres_user"]
    postgres_host     = var.deploy_rds_db ? module.rds[0].db_instance_address : module.ec2_database[0].private_dns
    create_database   = var.stats_create_database
  }
  nginx_config = {
    service_name        = "stats"
    backend_port        = 8050
    new_frontend_domain = var.new_frontend_domain
  }
  tags = local.final_tags
}

module "ec2_asg_eth_bytecode_db" {
  count  = var.eth_bytecode_db_enabled ? 1 : 0
  source = "./asg"
  ## ASG settings
  name                 = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-asg-eth-bytecode-db-instance"
  min_size             = var.eth_bytecode_db_replicas
  max_size             = var.eth_bytecode_db_replicas
  vpc_zone_identifier  = var.existed_vpc_id != "" ? var.existed_private_subnets_ids : module.vpc[0].private_subnets
  launch_template_name = "${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-eth-bytecode-db-launch-template"
  target_group_arns    = module.alb_eth_bytecode_db[0].target_group_arns
  ## Instance settings
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.eth_bytecode_db_instance_type
  create_iam_instance_profile = var.create_iam_instance_profile_ssm_policy
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = "role-${var.vpc_name != "" ? var.vpc_name : "existed-vpc"}-eth-bytecode-db"
  ## Init settings
  docker_compose_file_postfix = "_eth-bytecode-db"
  path_docker_compose_files   = var.path_docker_compose_files
  user                        = var.user
  security_groups             = module.app_eth_bytecode_db_sg.security_group_id
  docker_compose_config = {
    docker_image      = var.eth_bytecode_db_docker_image
    postgres_password = var.deploy_rds_db ? module.rds[0].db_instance_password : var.blockscout_settings["postgres_password"]
    postgres_user     = var.deploy_rds_db ? module.rds[0].db_instance_username : var.blockscout_settings["postgres_user"]
    postgres_host     = var.deploy_rds_db ? module.rds[0].db_instance_address : module.ec2_database[0].private_dns
    verifier_url      = var.verifier_enabled ? (var.verifier_url != "" ? var.verifier_url : "http://${module.alb_verifier[0].lb_dns_name}") : var.verifier_url
    create_database   = var.eth_bytecode_db_create_database
  }
  nginx_config = {
    service_name        = "eth-bytecode-db"
    backend_port        = 8050
    new_frontend_domain = var.new_frontend_domain
  }
  tags = local.final_tags
}

module "alb" {
  source              = "./alb"
  name                = "supernet"
  internal            = false
  vpc_id              = local.vpc_id_rule
  subnets             = local.subnets_rule
  backend_port        = 4000
  health_check_path   = "/"
  name_prefix         = "apiui-"
  security_groups     = module.lb_blockscout_ui_sg.security_group_id
  ssl_certificate_arn = var.ssl_certificate_arn
  tags                = local.final_tags
}

module "alb_new_frontend" {
  count               = var.new_frontend_enabled ? 1 : 0
  source              = "./alb"
  name                = "new-frontend"
  internal            = false
  vpc_id              = local.vpc_id_rule
  subnets             = local.subnets_rule
  backend_port        = 3000
  health_check_path   = "/"
  name_prefix         = "front-"
  security_groups     = module.lb_new_frontend_sg.security_group_id
  ssl_certificate_arn = var.ssl_certificate_arn
  tags                = local.final_tags
}

module "alb_verifier" {
  count               = var.verifier_enabled ? 1 : 0
  source              = "./alb"
  name                = "verifier"
  internal            = true
  vpc_id              = local.vpc_id_rule
  subnets             = local.subnets_rule
  backend_port        = 8050
  health_check_path   = "/api/v2/verifier/solidity/versions"
  name_prefix         = "verif-"
  security_groups     = module.lb_verifier_sg.security_group_id
  ssl_certificate_arn = var.new_frontend_enabled ? var.ssl_certificate_arn : ""
  tags                = local.final_tags
}

module "alb_visualizer" {
  count               = var.visualizer_enabled ? 1 : 0
  source              = "./alb"
  name                = "visualizer"
  internal            = var.new_frontend_enabled ? false : true
  vpc_id              = local.vpc_id_rule
  subnets             = local.subnets_rule
  backend_port        = 8050
  health_check_path   = "/health"
  name_prefix         = "viz-"
  security_groups     = module.lb_visualizer_sg.security_group_id
  ssl_certificate_arn = var.new_frontend_enabled ? var.ssl_certificate_arn : ""
  tags                = local.final_tags
}

module "alb_sig_provider" {
  count               = var.sig_provider_enabled ? 1 : 0
  source              = "./alb"
  name                = "sig-provider"
  internal            = true
  vpc_id              = local.vpc_id_rule
  subnets             = local.subnets_rule
  backend_port        = 8050
  health_check_path   = "/health?service="
  name_prefix         = "sig-"
  security_groups     = module.lb_sig_provider_sg.security_group_id
  ssl_certificate_arn = var.new_frontend_enabled ? var.ssl_certificate_arn : ""
  tags                = local.final_tags
}

module "alb_stats" {
  count               = var.stats_enabled ? 1 : 0
  source              = "./alb"
  name                = "stats"
  internal            = var.new_frontend_enabled ? false : true
  vpc_id              = local.vpc_id_rule
  subnets             = local.subnets_rule
  backend_port        = 8050
  health_check_path   = "/health?service="
  name_prefix         = "stat-"
  security_groups     = module.lb_stats_sg.security_group_id
  ssl_certificate_arn = var.new_frontend_enabled ? var.ssl_certificate_arn : ""
  tags                = local.final_tags
}

module "alb_eth_bytecode_db" {
  count               = var.eth_bytecode_db_enabled ? 1 : 0
  source              = "./alb"
  name                = "eth-bytecode-db"
  internal            = true
  vpc_id              = local.vpc_id_rule
  subnets             = local.subnets_rule
  backend_port        = 8050
  health_check_path   = "/health"
  name_prefix         = "byte-"
  security_groups     = module.lb_eth_bytecode_db_sg.security_group_id
  ssl_certificate_arn = var.new_frontend_enabled ? var.ssl_certificate_arn : ""
  tags                = local.final_tags
}