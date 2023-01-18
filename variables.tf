variable "ec2_instances_to_existed_vpc" {
  type    = any
  default = {}
}

variable "create_new_vpc" {
  type    = bool
  default = true
}

variable "path_docker_compose_files" {
  type    = string
  default = "/opt/blockscout"
}

variable "user" {
  description = "What user to service run as"
  type        = string
  default     = "root"
}

variable "ssh_key_name" {
  description = "Ssh key name"
  type        = string
  default     = ""
}

variable "image_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ssh_keys" {
  type    = map(string)
  default = {}
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC cidr"
  type        = string
  default     = "10.105.0.0/16"
}

variable "vpc_private_subnet_cidrs" {
  description = "Not required! You can set custom private subnets"
  type        = list(string)
  default     = null
}

variable "vpc_public_subnet_cidrs" {
  description = "Not required! You can set custom public subnets"
  type        = list(string)
  default     = null
}

variable "enabled_nat_gateway" {
  description = "Nat gateway enabled"
  type        = bool
  default     = true
}

variable "enabled_dns_hostnames" {
  description = "Autocreate dns names for ec2 instance in route53. Required for work with default DB"
  type        = bool
  default     = true
}

variable "azs" {
  description = "List of AZs"
  type        = list(string)
  default     = []
}

variable "ec2_instance_db" {
  description = "Create ec2 instance with postgresql db in docker"
  type        = bool
  default     = true
}

variable "docker_compose_values" {
  type = object({
    postgres_password             = string
    postgres_user                 = string
    postgres_host                 = string
    blockscout_docker_image       = string
    rpc_address                   = string
    chain_id                      = string
    rust_verification_service_url = string
  })
  default = {
    blockscout_docker_image       = "blockscout/blockscout-polygon-supernets:4.1.8-prerelease-651fbf3e"
    postgres_host                 = "postgres"
    postgres_password             = "postgres"
    postgres_user                 = "postgres"
    rpc_address                   = "https://rpc-supertestnet.polygon.technology"
    chain_id                      = "93201"
    rust_verification_service_url = "https://sc-verifier.aws-k8s.blockscout.com/"
  }
}

variable "custom_sg_rules" {
  description = "Add custom rules to SG"
  type        = list(map(string))
  default     = []
}

variable "custom_tags" {
  description = "Add custom tags for all resources managed by this script"
  type        = object({})
  default     = {}
}

variable "existed_vpc_id" {
  description = "Required for using existed vpc. ID of VPC"
  type        = string
  default     = ""
}

variable "deploy_rds" {
  description = "Enabled deploy rds"
  type        = bool
  default     = false
}

variable "existed_private_subnets_ids" {
  description = "List of existed id private subnets(For instances)"
  type        = list(string)
  default     = []
}

variable "existed_public_subnets_ids" {
  description = "List of existed if public subnets(For LB)"
  type        = list(string)
  default     = []
}

variable "ssl_certificate_arn" {
  description = ""
  type        = string
}
