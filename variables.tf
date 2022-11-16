variable "ec2_instances_to_existed_vpc" {
  type = any
  default = {}
}

variable "new_vpcs" {
  type    = any
  default = {}
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

variable "image_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ssh_keys" {
  type    = map(string)
  default = {}
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
  type    = list(map(string))
  default = []
}