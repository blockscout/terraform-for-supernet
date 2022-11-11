# Module for create vpc resources, security groups, ec2
Example:
```
locals {
  region = "us-east-1"
  tags = {
    terraform_managed = true
  }

}
module "vpc" {
  source = "./aws"
  ssh_keys = {
    key-name = "ssh-rsa AAAAB3Nz...cIVC9ODX2bJyG3zbFyeAy83U="
  }
  vpcs = {
    vpc-supernet = {
      name                 = "vpc-supernet"
      cidr                 = "10.5.0.0/16"
      azs                  = ["${local.region}a", "${local.region}b", "${local.region}c"]
      private_subnets      = ["10.5.1.0/24", "10.5.2.0/24", "10.5.3.0/24"]
      public_subnets       = ["10.5.101.0/24", "10.5.102.0/24", "10.5.103.0/24"]
      enable_nat_gateway   = true
      enable_dns_hostnames = true
      tags                 = local.tags
      ec2 = [
        {
          name                        = "test"
          az                          = "${local.region}a"
          instance_type               = "t2.medium"
          access_type                 = "public"
          create_iam_instance_profile = true
          key_name             = "key-name"
        }
      ]
    }
  }
}
```