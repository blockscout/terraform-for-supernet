#module "ec2_instances_to_existed_vpc" {
#  source                      = "terraform-aws-modules/ec2-instance/aws"
#  version                     = "4.2.1"
#  for_each                    = var.ec2_instances_to_existed_vpc
#  name                        = each.key
#  ami                         = data.aws_ami.ubuntu.id
#  instance_type               = each.value.instance_type
#  key_name                    = each.value.key_name
#  monitoring                  = false
#  vpc_security_group_ids      = each.value.sg_id
#  subnet_id                   = each.value.subnet_id
#  create_iam_instance_profile = each.value.create_iam_instance_profile
#  tags                        = each.value.tags
#  user_data                   = templatefile(
#    "${path.module}/templates/init_script.tftpl",
#    {
#      docker_compose_str = templatefile(
#        "${path.module}/templates/docker_compose.tftpl",
#        {
#          postgres_password             = var.docker_compose_values["postgres_password"]
#          postgres_user                 = var.docker_compose_values["postgres_user"]
#          blockscout_docker_image       = var.docker_compose_values["blockscout_docker_image"]
#          rpc_address                   = var.docker_compose_values["rpc_address"]
#          postgres_host                 = var.docker_compose_values["postgres_host"]
#          chain_id                      = var.docker_compose_values["chain_id"]
#          rust_verification_service_url = var.docker_compose_values["rust_verification_service_url"]
#        }
#      )
#      path_docker_compose_files = var.path_docker_compose_files
#      user                      = var.user
#    }
#  )
#  user_data_replace_on_change = true
#}