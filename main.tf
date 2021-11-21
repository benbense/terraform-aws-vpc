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
    "Name" = "${var.vpc_name}"
  }
}

# Subnets Creation
resource "aws_subnet" "private_subnets" {
  count             = var.availability_zones
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.cidr_size, 8, count.index)
  tags = {
    "Name" = "Private-${count.index}"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = var.availability_zones
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(var.cidr_size, 8, 100 + count.index)
  tags = {
    "Name" = "Public-${count.index}"
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
  count         = length(aws_subnet.private_subnets)
  subnet_id     = aws_subnet.private_subnets[count.index].id
  allocation_id = aws_eip.ngw-eip[count.index].id
  tags = {
    "Name" = "private-ngw-${count.index}"
  }
}

# Elastic IP's Creation
resource "aws_eip" "ngw-eip" {
  count = length(aws_subnet.private_subnets)
  tags = {
    "Name" = "NAT-{count.index}"
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
