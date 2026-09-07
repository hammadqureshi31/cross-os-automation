output "vpc_id" {
  description = "Id of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "security_group_id" {
  description = "ID of the dev security group"
  value       = module.security_group.security_group_id
}

output "instance_id" {
  description = "ID of the dev EC2 instance"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "Public IP of the dev EC2 instance"
  value       = module.ec2.public_ip
}