output "instance_id" {
  description = "The name of the buckets."
  value       = {
    for k, v in module.ec2_instances_to_existed_vpc :k => v.id
  }
}
