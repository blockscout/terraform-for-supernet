module "ec2_asg" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  version                   = "v6.7.1"
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.vpc_zone_identifier
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 100
    }
    triggers = ["tag"]
  }
  launch_template_name        = var.launch_template_name
  launch_template_description = "Launch template"
  update_default_version      = true
  image_id                    = var.image_id
  instance_type               = var.instance_type
  ebs_optimized               = false
  enable_monitoring           = false
  create_iam_instance_profile = var.create_iam_instance_profile
  iam_instance_profile_arn    = var.iam_instance_profile_arn
  iam_role_name               = var.iam_role_name
  iam_role_path               = "/"
  iam_role_description        = "IAM role"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  user_data = base64encode(templatefile(
    "${path.module}/../templates/init_script.tftpl",
    {
      docker_compose_str = templatefile(
        "${path.module}/../templates/docker_compose${var.docker_compose_file_postfix}.tftpl",
        var.docker_compose_config
      )
      nginx_config = var.nginx_config != {} ? templatefile(
        "${path.module}/../templates/nginx.tftpl",
        var.nginx_config
      ) : ""
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
      security_groups       = [var.security_groups]
    }
  ]
  tag_specifications = [
    {
      resource_type = "instance"
      tags          = var.tags
    },
    {
      resource_type = "volume"
      tags          = var.tags
    }
  ]
  target_group_arns = var.target_group_arns
  tags              = var.tags
}