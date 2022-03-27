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

output "iam_role_arn" {
  description = "ARN Of Describe Instances Role"
  value       = aws_iam_role.describe_instances.arn
}
output "kandula_ssl_cert" {
  description = "ARN of SSL Certificate"
  value       = aws_iam_server_certificate.kandula_ssl_cert.arn
}

output "route53_zone_id" {
  description = "Hosted Zone ID"
  value       = aws_route53_zone.private.zone_id
}

output "cidr_block" {
  description = "VPC CIDR Block"
  value = aws_vpc.vpc.cidr_block
}