<!-- BEGIN_TF_DOCS -->
# Module for deploy blockscout to AWS
Examples:   
New vpc and deploy database rds:
```
locals {
  region = "us-east-1"
  tags = {
    terraform_managed = true
    project           = "blockscout-supernet"
  }
}
module "vpc" {
  source = "./aws"
  vpc_name               = "name"
  ssl_certificate_arn    = "<arn>"
  deploy_ec2_instance_db = false
  deploy_rds_db          = true
  tags                   = local.tags
}
```
!!! For work with existed vpc needs a subnet group: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html#USER_VPC.Subnets  
Existed vpc and deploy database rds:
```
locals {
  region = "us-east-1"
  tags = {
    terraform_managed = true
    project           = "blockscout-supernet"
  }
}
module "vpc" {
  source = "./aws"
  existed_vpc_id = "vpc-05626****"
  existed_private_subnets_ids = ["subnet-*", "subnet-*", "subnet-*"]
  existed_public_subnets_ids = ["subnet-*", "subnet-*", "subnet-*"]
  existed_rds_subnet_group_name = "<name>"
  ssl_certificate_arn = "<arn>"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.67.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.67.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | ./alb | n/a |
| <a name="module_alb_eth_bytecode_db"></a> [alb\_eth\_bytecode\_db](#module\_alb\_eth\_bytecode\_db) | ./alb | n/a |
| <a name="module_alb_new_frontend"></a> [alb\_new\_frontend](#module\_alb\_new\_frontend) | ./alb | n/a |
| <a name="module_alb_sig_provider"></a> [alb\_sig\_provider](#module\_alb\_sig\_provider) | ./alb | n/a |
| <a name="module_alb_stats"></a> [alb\_stats](#module\_alb\_stats) | ./alb | n/a |
| <a name="module_alb_verifier"></a> [alb\_verifier](#module\_alb\_verifier) | ./alb | n/a |
| <a name="module_alb_visualizer"></a> [alb\_visualizer](#module\_alb\_visualizer) | ./alb | n/a |
| <a name="module_app_blockscout_indexer_sg"></a> [app\_blockscout\_indexer\_sg](#module\_app\_blockscout\_indexer\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_app_blockscout_ui_sg"></a> [app\_blockscout\_ui\_sg](#module\_app\_blockscout\_ui\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_app_eth_bytecode_db_sg"></a> [app\_eth\_bytecode\_db\_sg](#module\_app\_eth\_bytecode\_db\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_app_new_frontend_sg"></a> [app\_new\_frontend\_sg](#module\_app\_new\_frontend\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_app_sig_provider_sg"></a> [app\_sig\_provider\_sg](#module\_app\_sig\_provider\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_app_stats_sg"></a> [app\_stats\_sg](#module\_app\_stats\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_app_verifier_sg"></a> [app\_verifier\_sg](#module\_app\_verifier\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_app_visualizer_sg"></a> [app\_visualizer\_sg](#module\_app\_visualizer\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_db_sg"></a> [db\_sg](#module\_db\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_ec2_asg_api_and_ui"></a> [ec2\_asg\_api\_and\_ui](#module\_ec2\_asg\_api\_and\_ui) | ./asg | n/a |
| <a name="module_ec2_asg_eth_bytecode_db"></a> [ec2\_asg\_eth\_bytecode\_db](#module\_ec2\_asg\_eth\_bytecode\_db) | ./asg | n/a |
| <a name="module_ec2_asg_indexer"></a> [ec2\_asg\_indexer](#module\_ec2\_asg\_indexer) | ./asg | n/a |
| <a name="module_ec2_asg_new_frontend"></a> [ec2\_asg\_new\_frontend](#module\_ec2\_asg\_new\_frontend) | ./asg | n/a |
| <a name="module_ec2_asg_sig_provider"></a> [ec2\_asg\_sig\_provider](#module\_ec2\_asg\_sig\_provider) | ./asg | n/a |
| <a name="module_ec2_asg_stats"></a> [ec2\_asg\_stats](#module\_ec2\_asg\_stats) | ./asg | n/a |
| <a name="module_ec2_asg_verifier"></a> [ec2\_asg\_verifier](#module\_ec2\_asg\_verifier) | ./asg | n/a |
| <a name="module_ec2_asg_visualizer"></a> [ec2\_asg\_visualizer](#module\_ec2\_asg\_visualizer) | ./asg | n/a |
| <a name="module_ec2_database"></a> [ec2\_database](#module\_ec2\_database) | terraform-aws-modules/ec2-instance/aws | 4.2.1 |
| <a name="module_lb_blockscout_ui_sg"></a> [lb\_blockscout\_ui\_sg](#module\_lb\_blockscout\_ui\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_lb_eth_bytecode_db_sg"></a> [lb\_eth\_bytecode\_db\_sg](#module\_lb\_eth\_bytecode\_db\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_lb_new_frontend_sg"></a> [lb\_new\_frontend\_sg](#module\_lb\_new\_frontend\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_lb_sig_provider_sg"></a> [lb\_sig\_provider\_sg](#module\_lb\_sig\_provider\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_lb_stats_sg"></a> [lb\_stats\_sg](#module\_lb\_stats\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_lb_verifier_sg"></a> [lb\_verifier\_sg](#module\_lb\_verifier\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_lb_visualizer_sg"></a> [lb\_visualizer\_sg](#module\_lb\_visualizer\_sg) | terraform-aws-modules/security-group/aws | 4.16.0 |
| <a name="module_rds"></a> [rds](#module\_rds) | terraform-aws-modules/rds/aws | 5.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.18.1 |

## Resources

| Name | Type |
|------|------|
| [random_string.secret_key_base](https://registry.terraform.io/providers/hashicorp/random/3.4.3/docs/resources/string) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_blockscout_settings"></a> [blockscout\_settings](#input\_blockscout\_settings) | Settings of blockscout app | <pre>object({<br>    postgres_password             = optional(string, "postgres")<br>    postgres_user                 = optional(string, "postgres")<br>    postgres_host                 = optional(string, "postgres")<br>    blockscout_docker_image       = optional(string, "blockscout/blockscout-polygon-supernets:5.1.3-prerelease-61c1238e")<br>    rpc_address                   = optional(string, "https://rpc-supertestnet.polygon.technology")<br>    chain_id                      = optional(string, "93201")<br>    rust_verification_service_url = optional(string, "https://sc-verifier.aws-k8s.blockscout.com/")<br>    ws_address                    = optional(string, "")<br>    visualize_sol2uml_service_url = optional(string, "")<br>    sig_provider_service_url      = optional(string, "")<br>  })</pre> | `{}` | no |
| <a name="input_create_iam_instance_profile_ssm_policy"></a> [create\_iam\_instance\_profile\_ssm\_policy](#input\_create\_iam\_instance\_profile\_ssm\_policy) | Determines whether an IAM instance profile with SSM policy is created or to use an existing IAM instance profile | `string` | `false` | no |
| <a name="input_deploy_ec2_instance_db"></a> [deploy\_ec2\_instance\_db](#input\_deploy\_ec2\_instance\_db) | Create ec2 instance with postgresql db in docker | `bool` | `true` | no |
| <a name="input_deploy_rds_db"></a> [deploy\_rds\_db](#input\_deploy\_rds\_db) | Enabled deploy rds | `bool` | `false` | no |
| <a name="input_enabled_dns_hostnames"></a> [enabled\_dns\_hostnames](#input\_enabled\_dns\_hostnames) | Autocreate dns names for ec2 instance in route53. Required for work with default DB | `bool` | `true` | no |
| <a name="input_enabled_nat_gateway"></a> [enabled\_nat\_gateway](#input\_enabled\_nat\_gateway) | Nat gateway enabled | `bool` | `true` | no |
| <a name="input_eth_bytecode_db_create_database"></a> [eth\_bytecode\_db\_create\_database](#input\_eth\_bytecode\_db\_create\_database) | Create database in application start | `bool` | `true` | no |
| <a name="input_eth_bytecode_db_docker_image"></a> [eth\_bytecode\_db\_docker\_image](#input\_eth\_bytecode\_db\_docker\_image) | Docker image of eth-bytecode-db | `string` | `"ghcr.io/blockscout/eth-bytecode-db:main"` | no |
| <a name="input_eth_bytecode_db_enabled"></a> [eth\_bytecode\_db\_enabled](#input\_eth\_bytecode\_db\_enabled) | eth-bytecode-db deploy | `bool` | `true` | no |
| <a name="input_eth_bytecode_db_instance_type"></a> [eth\_bytecode\_db\_instance\_type](#input\_eth\_bytecode\_db\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_eth_bytecode_db_replicas"></a> [eth\_bytecode\_db\_replicas](#input\_eth\_bytecode\_db\_replicas) | Number of eth-bytecode-db replicas | `number` | `1` | no |
| <a name="input_existed_private_subnets_ids"></a> [existed\_private\_subnets\_ids](#input\_existed\_private\_subnets\_ids) | List of existed id private subnets(For instances) | `list(string)` | `[]` | no |
| <a name="input_existed_public_subnets_ids"></a> [existed\_public\_subnets\_ids](#input\_existed\_public\_subnets\_ids) | List of existed if public subnets(For LB) | `list(string)` | `[]` | no |
| <a name="input_existed_rds_subnet_group_name"></a> [existed\_rds\_subnet\_group\_name](#input\_existed\_rds\_subnet\_group\_name) | Name of subnet group for RDS deploy | `string` | `""` | no |
| <a name="input_existed_vpc_id"></a> [existed\_vpc\_id](#input\_existed\_vpc\_id) | Required for using existed vpc. ID of VPC | `string` | `""` | no |
| <a name="input_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#input\_iam\_instance\_profile\_arn) | Amazon Resource Name (ARN) of an existing IAM instance profile. Used when `create_iam_instance_profile_ssm_policy` = `false` | `string` | `null` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | OS image mask | `string` | `"ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-202304*"` | no |
| <a name="input_image_owner"></a> [image\_owner](#input\_image\_owner) | ID of image owner | `string` | `"679593333241"` | no |
| <a name="input_indexer_instance_type"></a> [indexer\_instance\_type](#input\_indexer\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_new_frontend_enabled"></a> [new\_frontend\_enabled](#input\_new\_frontend\_enabled) | Switch to new frontend | `bool` | `true` | no |
| <a name="input_new_frontend_instance_type"></a> [new\_frontend\_instance\_type](#input\_new\_frontend\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_new_frontend_settings"></a> [new\_frontend\_settings](#input\_new\_frontend\_settings) | Settings of new frontend | <pre>object({<br>    docker_image       = optional(string, "ghcr.io/blockscout/frontend:main")<br>    stats_api_url      = optional(string)<br>    rpc_address        = optional(string, "https://rpc-supertestnet.polygon.technology")<br>    visualizer_api_url = optional(string)<br>    backend_url        = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_new_frontend_url"></a> [new\_frontend\_url](#input\_new\_frontend\_url) | Domain of new frontend | `string` | `""` | no |
| <a name="input_path_docker_compose_files"></a> [path\_docker\_compose\_files](#input\_path\_docker\_compose\_files) | Path in ec2 instance for blockscout files | `string` | `"/opt/blockscout"` | no |
| <a name="input_rds_allocated_storage"></a> [rds\_allocated\_storage](#input\_rds\_allocated\_storage) | Size of rds storage | `number` | `20` | no |
| <a name="input_rds_instance_type"></a> [rds\_instance\_type](#input\_rds\_instance\_type) | AWS RDS instance type | `string` | `"db.t3.large"` | no |
| <a name="input_rds_max_allocated_storage"></a> [rds\_max\_allocated\_storage](#input\_rds\_max\_allocated\_storage) | Max size of rds storage | `number` | `300` | no |
| <a name="input_rds_multi_az"></a> [rds\_multi\_az](#input\_rds\_multi\_az) | Creates a primary DB instance and a standby DB instance in a different AZ. Provides high availability and data redundancy, but the standby DB instance doesn't support connections for read workloads. | `bool` | `false` | no |
| <a name="input_sig_provider_docker_image"></a> [sig\_provider\_docker\_image](#input\_sig\_provider\_docker\_image) | Docker image of sig-provider | `string` | `"ghcr.io/blockscout/sig-provider:main"` | no |
| <a name="input_sig_provider_enabled"></a> [sig\_provider\_enabled](#input\_sig\_provider\_enabled) | sig-provider deploy | `bool` | `false` | no |
| <a name="input_sig_provider_instance_type"></a> [sig\_provider\_instance\_type](#input\_sig\_provider\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_sig_provider_replicas"></a> [sig\_provider\_replicas](#input\_sig\_provider\_replicas) | Number of sig-provider replicas | `number` | `1` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `true` | no |
| <a name="input_ssl_certificate_arn"></a> [ssl\_certificate\_arn](#input\_ssl\_certificate\_arn) | Certificate for ALB. If using new frontend. Certificate should be valid for main\_domain and all domains of microservices | `string` | `""` | no |
| <a name="input_stats_create_database"></a> [stats\_create\_database](#input\_stats\_create\_database) | Create database in application start | `bool` | `true` | no |
| <a name="input_stats_docker_image"></a> [stats\_docker\_image](#input\_stats\_docker\_image) | Docker image of stats | `string` | `"ghcr.io/blockscout/stats:main"` | no |
| <a name="input_stats_enabled"></a> [stats\_enabled](#input\_stats\_enabled) | stats deploy | `bool` | `true` | no |
| <a name="input_stats_instance_type"></a> [stats\_instance\_type](#input\_stats\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_stats_replicas"></a> [stats\_replicas](#input\_stats\_replicas) | Number of stats replicas | `number` | `1` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Add custom tags for all resources managed by this script | `map(string)` | `{}` | no |
| <a name="input_ui_and_api_instance_type"></a> [ui\_and\_api\_instance\_type](#input\_ui\_and\_api\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_user"></a> [user](#input\_user) | What user to service run as | `string` | `"root"` | no |
| <a name="input_verifier_enabled"></a> [verifier\_enabled](#input\_verifier\_enabled) | Verifier deploy | `bool` | `true` | no |
| <a name="input_verifier_instance_type"></a> [verifier\_instance\_type](#input\_verifier\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_verifier_replicas"></a> [verifier\_replicas](#input\_verifier\_replicas) | Number of verifier replicas | `number` | `2` | no |
| <a name="input_verifier_settings"></a> [verifier\_settings](#input\_verifier\_settings) | Settings of verifier | <pre>object({<br>    docker_image                       = optional(string, "ghcr.io/blockscout/smart-contract-verifier:main")<br>    solidity_fetcher_list_url          = optional(string, "https://solc-bin.ethereum.org/linux-amd64/list.json")<br>    solidity_refresh_versions_schedule = optional(string, "0 0 * * * * *")<br>    vyper_fetcher_list_url             = optional(string, "https://raw.githubusercontent.com/blockscout/solc-bin/main/vyper.list.json")<br>    vyper_refresh_versions_schedule    = optional(string, "0 0 * * * * *")<br>    sourcify_api_url                   = optional(string, "https://sourcify.dev/server/")<br>  })</pre> | `{}` | no |
| <a name="input_verifier_url"></a> [verifier\_url](#input\_verifier\_url) | Url of verifier | `string` | `""` | no |
| <a name="input_visualizer_docker_image"></a> [visualizer\_docker\_image](#input\_visualizer\_docker\_image) | Docker image of visualizer | `string` | `"ghcr.io/blockscout/visualizer:latest"` | no |
| <a name="input_visualizer_enabled"></a> [visualizer\_enabled](#input\_visualizer\_enabled) | Visualizer deploy | `bool` | `true` | no |
| <a name="input_visualizer_instance_type"></a> [visualizer\_instance\_type](#input\_visualizer\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_visualizer_replicas"></a> [visualizer\_replicas](#input\_visualizer\_replicas) | Number of visualizer replicas | `number` | `2` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC cidr | `string` | `"10.105.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPC name | `string` | `""` | no |
| <a name="input_vpc_private_subnet_cidrs"></a> [vpc\_private\_subnet\_cidrs](#input\_vpc\_private\_subnet\_cidrs) | Not required! You can set custom private subnets | `list(string)` | `null` | no |
| <a name="input_vpc_public_subnet_cidrs"></a> [vpc\_public\_subnet\_cidrs](#input\_vpc\_public\_subnet\_cidrs) | Not required! You can set custom public subnets | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_blockscout_url"></a> [blockscout\_url](#output\_blockscout\_url) | DNS name of frontend |
<!-- END_TF_DOCS -->