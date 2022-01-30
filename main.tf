###############################################################
# This module creates:
# VPC
# Private Subnets
# Public Subnets
# Internet Gateway
# NAT Gateways
# Elastic IP's
# Public Route Tables
# Private Route Tables
###############################################################

# Fetch available AZ's
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Creation
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_size
  tags = {
    "Name"                                        = "${var.vpc_name}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Subnets Creation
resource "aws_subnet" "private_subnets" {
  count             = var.availability_zones
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.cidr_size, 8, count.index)
  tags = {
    "Name"                                        = "Private-${count.index}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = var.availability_zones
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(var.cidr_size, 8, 100 + count.index)
  tags = {
    "Name"                                        = "Public-${count.index + 100}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

# Internet Gateway Creation
resource "aws_internet_gateway" "public-igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "public-igw"
  }
}

# NAT Gateway Creation
resource "aws_nat_gateway" "private-ngw" {
  count         = length(aws_subnet.public_subnets)
  subnet_id     = aws_subnet.public_subnets[count.index].id
  allocation_id = aws_eip.ngw-eip[count.index].id
  tags = {
    "Name" = "ngw-${count.index}"
  }
}

# Elastic IP's Creation
resource "aws_eip" "ngw-eip" {
  count = length(aws_subnet.public_subnets)
  tags = {
    "Name" = "NAT-${count.index}"
  }
}

# Route Tables Creation
resource "aws_route_table" "public_web" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "public_web"
  }
}

resource "aws_route_table" "private_rt" {
  count  = length(aws_subnet.private_subnets)
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "private_rt-${count.index}"
  }
}

resource "aws_route" "all_gateway" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_web.id
  gateway_id             = aws_internet_gateway.public-igw.id
}

resource "aws_route" "private_routes" {
  count                  = length(aws_route_table.private_rt)
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private_rt[count.index].id
  gateway_id             = aws_nat_gateway.private-ngw[count.index].id
}

resource "aws_route_table_association" "private_rt_assign" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

resource "aws_route_table_association" "public_rt_assign" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_web.id
}

resource "aws_iam_role" "describe_instances" {
  name = "describe_instances"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      },
    ]
  })
}

resource "aws_iam_policy" "describe_instances" {
  name = "describe_instances"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:Describe*",
          "sts:AssumeRole",
          "eks:DescribeCluster"
        ],
        "Resource" : "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "describe_instances" {
  name       = "describe_instances"
  roles      = [aws_iam_role.describe_instances.name]
  policy_arn = aws_iam_policy.describe_instances.arn
}

resource "aws_iam_instance_profile" "describe_instances" {
  name = "describe_instances"
  role = aws_iam_role.describe_instances.name
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name = "${var.vpc_name}-eks-${random_string.suffix.result}"
}

resource "aws_iam_server_certificate" "kandula_ssl_cert" {
  name             = "kandula_ssl_cert"
  certificate_body = var.cert_body
  private_key      = var.cert_private_key
}
