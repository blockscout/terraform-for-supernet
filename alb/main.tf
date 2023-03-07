module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "8.2.1"
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.subnets
  security_groups    = [var.security_groups]
  target_groups = [
    {
      name_prefix      = var.name_prefix
      backend_protocol = "HTTP"
      backend_port     = var.backend_port
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = var.health_check_path
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]
  http_tcp_listeners = var.ssl_certificate_arn != "" ? [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }] : [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "forward"
      redirect    = {}
  }]
  https_listeners = var.ssl_certificate_arn != "" ? [
    {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = var.ssl_certificate_arn
    }
  ] : []
  tags = var.tags
}