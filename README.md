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

| Name | Version  |
|------|----------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ">= 1.3.0" |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ">= 4.39.0" |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ">= 4.39" |

## Modules

| Name     | Source                                                                | Version |
|----------|-----------------------------------------------------------------------|---------|
| VPC      | https://github.com/terraform-aws-modules/terraform-aws-vpc            | 3.18.1  |
| SG       | https://github.com/terraform-aws-modules/terraform-aws-security-group | 4.16.0  |
| Key pair | https://github.com/terraform-aws-modules/terraform-aws-key-pair       | n/a     |
| RDS      | https://github.com/terraform-aws-modules/terraform-aws-rds            | 5.1.1   |
| EC2      | https://github.com/terraform-aws-modules/terraform-aws-ec2-instance   | 4.2.1   |
| ALB      | https://github.com/terraform-aws-modules/terraform-aws-alb            | 8.2.1   |
| ASG      | https://github.com/terraform-aws-modules/terraform-aws-autoscaling    | v6.7.1  |


## Resources

| Name | Type |
|------|------|
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default                                                                                                                                                                                                                                                                                                                                                                                                                                   | Required |
|------|-------------|------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| <a name="input_blockscout_settings"></a> [blockscout\_settings](#input\_blockscout\_settings) | Settings of blockscout app | <pre>object({<br>    postgres_password             = string<br>    postgres_user                 = string<br>    postgres_host                 = string<br>    blockscout_docker_image       = string<br>    rpc_address                   = string<br>    chain_id                      = string<br>    rust_verification_service_url = string<br>    ws_address                    = string<br>  })</pre> | <pre>{<br>  "blockscout_docker_image": "blockscout/blockscout-polygon-supernets:4.1.8-prerelease-651fbf3e",<br>  "chain_id": "93201",<br>  "postgres_host": "postgres",<br>  "postgres_password": "postgres",<br>  "postgres_user": "postgres",<br>  "rpc_address": "https://rpc-supertestnet.polygon.technology",<br>  "rust_verification_service_url": "https://sc-verifier.aws-k8s.blockscout.com/", <br>  "ws_address": ""<br>}</pre> | no |
| <a name="input_create_iam_instance_profile_ssm_policy"></a> [create\_iam\_instance\_profile\_ssm\_policy](#input\_create\_iam\_instance\_profile\_ssm\_policy) | Determines whether an IAM instance profile with SSM policy is created or to use an existing IAM instance profile | `string` | `false` | no |
| <a name="input_deploy_ec2_instance_db"></a> [deploy\_ec2\_instance\_db](#input\_deploy\_ec2\_instance\_db) | Create ec2 instance with postgresql db in docker | `bool` | `true` | no |
| <a name="input_deploy_rds_db"></a> [deploy\_rds\_db](#input\_deploy\_rds\_db) | Enabled deploy rds | `bool` | `false` | no |
| <a name="input_enabled_dns_hostnames"></a> [enabled\_dns\_hostnames](#input\_enabled\_dns\_hostnames) | Autocreate dns names for ec2 instance in route53. Required for work with default DB | `bool` | `true` | no |
| <a name="input_enabled_nat_gateway"></a> [enabled\_nat\_gateway](#input\_enabled\_nat\_gateway) | Nat gateway enabled | `bool` | `true` | no |
| <a name="input_existed_private_subnets_ids"></a> [existed\_private\_subnets\_ids](#input\_existed\_private\_subnets\_ids) | List of existed id private subnets(For instances) | `list(string)` | `[]` | no |
| <a name="input_existed_public_subnets_ids"></a> [existed\_public\_subnets\_ids](#input\_existed\_public\_subnets\_ids) | List of existed if public subnets(For LB) | `list(string)` | `[]` | no |
| <a name="input_existed_rds_subnet_group_name"></a> [existed\_rds\_subnet\_group\_name](#input\_existed\_rds\_subnet\_group\_name) | Name of subnet group for RDS deploy | `string` | `""` | no |
| <a name="input_existed_vpc_id"></a> [existed\_vpc\_id](#input\_existed\_vpc\_id) | Required for using existed vpc. ID of VPC | `string` | `""` | no |
| <a name="input_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#input\_iam\_instance\_profile\_arn) | Amazon Resource Name (ARN) of an existing IAM instance profile. Used when `create_iam_instance_profile_ssm_policy` = `false` | `string` | `null` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | OS image mask | `string` | `"ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"` | no |
| <a name="input_image_owner"></a> [image\_owner](#input\_image\_owner) | ID of image owner | `string` | `"679593333241"` | no |
| <a name="input_indexer_instance_type"></a> [indexer\_instance\_type](#input\_indexer\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_path_docker_compose_files"></a> [path\_docker\_compose\_files](#input\_path\_docker\_compose\_files) | Path in ec2 instance for blockscout files | `string` | `"/opt/blockscout"` | no |
| <a name="input_rds_allocated_storage"></a> [rds\_allocated\_storage](#input\_rds\_allocated\_storage) | Size of rds storage | `number` | `20` | no |
| <a name="input_rds_instance_type"></a> [rds\_instance\_type](#input\_rds\_instance\_type) | AWS RDS instance type | `string` | `"db.t3.large"` | no |
| <a name="input_rds_max_allocated_storage"></a> [rds\_max\_allocated\_storage](#input\_rds\_max\_allocated\_storage) | Max size of rds storage | `number` | `300` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `true` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Ssh key name | `string` | `""` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | Create ssh keys | `map(string)` | `{}` | no |
| <a name="input_ssl_certificate_arn"></a> [ssl\_certificate\_arn](#input\_ssl\_certificate\_arn) | Certificate for ALB | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Add custom tags for all resources managed by this script | `map(string)` | `{}` | no |
| <a name="input_ui_and_api_instance_type"></a> [ui\_and\_api\_instance\_type](#input\_ui\_and\_api\_instance\_type) | AWS instance type | `string` | `"t2.medium"` | no |
| <a name="input_user"></a> [user](#input\_user) | What user to service run as | `string` | `"root"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC cidr | `string` | `"10.105.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPC name | `string` | `""` | no |
| <a name="input_vpc_private_subnet_cidrs"></a> [vpc\_private\_subnet\_cidrs](#input\_vpc\_private\_subnet\_cidrs) | Not required! You can set custom private subnets | `list(string)` | `null` | no |
| <a name="input_vpc_public_subnet_cidrs"></a> [vpc\_public\_subnet\_cidrs](#input\_vpc\_public\_subnet\_cidrs) | Not required! You can set custom public subnets | `list(string)` | `null` | no |

## Outputs

No outputs.
