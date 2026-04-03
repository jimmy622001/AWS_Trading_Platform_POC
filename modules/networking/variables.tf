variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "customer_gateway_ip" {
  description = "Public IP address for customer gateway"
  type        = string
}

variable "onpremises_cidr" {
  description = "On-premises network CIDR"
  type        = string
}
