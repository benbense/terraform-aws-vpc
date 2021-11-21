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
