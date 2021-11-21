variable "cidr_size" {
  description = "VPC CIDR Size"
  type        = string
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "availability_zones" {
  description = "Number of availability zones to account for"
  type        = number
}
