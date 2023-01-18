#output "instance_id" {
#  description = "The name of the buckets."
#  value       = {
#    for k, v in merge(module.ec2_instances_to_existed_vpc, module.ec2_instance_to_new_vpc) :k => v.id
#  }
#}
