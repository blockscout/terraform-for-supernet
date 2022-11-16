# Module for create vpc resources, security groups, ec2
Locals example:
```
locals {
  region = "us-east-1"
  tags = {
    terraform_managed = true
  }
}
```
Create new vpc, sg, ec2:
```
module "vpc" {
  source = "./aws"
  ssh_keys = {
    key-name = "ssh-rsa AAAAB3Nz...cIVC9ODX2bJyG3zbFyeAy83U="
  }
  custom_sg_rules = [
    {
      from_port   = 4000
      to_port     = 4000
      protocol    = "tcp"
      description = "Blockscout port"
      cidr_blocks = "10.5.0.0/16"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
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
Use existed vpc:
```
module "vpc" {
  source = "./aws"
  ssh_keys = {
    key-name = "ssh-rsa AAAAB3Nza..."
  }
  ec2_instances_to_existed_vpc = {
    supernet-test = {
      instance_type = "t2.medium"
      create_iam_instance_profile = false
      key_name = "key-name"
      subnet_id = "subnet-0cf30a"
      sg_id     = ["sg-0c2e06"]
      tags      = {}
    }
  }
```
Example of configration lb module:
```

  source  = "terraform-aws-modules/alb/aws"
  version = "8.2.1"
  name = "supernet-test"

  load_balancer_type = "application"

  vpc_id             = "vpc-05626f"
  subnets            = ["subnet-0cf30ac", "subnet-0120c87"]
  security_groups    = ["sg-0c2e06c"]

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        my_target = {
          target_id = module.vpc.instance_id["supernet-test"]
          port = 4000
        }
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }

  depends_on = [
    module.vpc
  ]
}
```