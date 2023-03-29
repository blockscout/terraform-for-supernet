output "blockscout_url" {
  description = "DNS name of frontend"
  value       = module.alb.lb_dns_name
}