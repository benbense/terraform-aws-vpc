output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "available_zone_names" {
  description = "Available availability zones names"
  value       = data.aws_availability_zones.available.names
}

output "public_subnets_ids" {
  description = "ID of the public subnets"
  value       = aws_subnet.public_subnets.*.id
}

output "private_subnets_ids" {
  description = "ID of the private subnets"
  value       = aws_subnet.private_subnets.*.id
}

output "instance_profile_name" {
  description = "IAM Policy name"
  value       = aws_iam_instance_profile.describe_instances.name
}

output "cluster_name" {
  description = "EKS Cluster name"
  value       = local.cluster_name
}
