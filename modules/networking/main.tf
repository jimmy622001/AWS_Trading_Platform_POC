# VPC and Networking Infrastructure
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# VPC Flow Logs for network monitoring
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-vpc-flow-log"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flowlog/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.vpc_flow_log.arn

  tags = {
    Name = "${var.project_name}-vpc-flow-log-group"
  }
}

resource "aws_kms_key" "vpc_flow_log" {
  description             = "KMS key for VPC Flow Logs encryption"
  deletion_window_in_days = 7

  tags = {
    Name = "${var.project_name}-vpc-flow-log-key"
  }
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "${var.project_name}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_log_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonVPCFlowLogsFullAccess"
  role       = aws_iam_role.vpc_flow_log_role.name
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${var.azs[count.index]}"
    Type = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-${var.azs[count.index]}"
    Type = "Private"
  }
}

# NAT Gateways
resource "aws_eip" "nat" {
  count = length(var.azs)

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${var.azs[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count = length(var.azs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.azs[count.index]}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPC Endpoints for private connectivity
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  tags = {
    Name = "${var.project_name}-dynamodb-endpoint"
  }
}

# Kinesis VPC Endpoints for ultra-low latency trading
resource "aws_vpc_endpoint" "kinesis_streams" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.kinesis-streams"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${var.project_name}-kinesis-streams-endpoint"
  }
}

resource "aws_vpc_endpoint" "kinesis_firehose" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.kinesis-firehose"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name = "${var.project_name}-kinesis-firehose-endpoint"
  }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-vpc-endpoints-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg"
  }
}

# Customer Gateway for VPN
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = {
    Name = "${var.project_name}-customer-gateway"
  }
}

# VPN Gateway
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-vpn-gateway"
  }
}

# Site-to-Site VPN Connection
resource "aws_vpn_connection" "main" {
  customer_gateway_id = aws_customer_gateway.main.id
  type                = "ipsec.1"
  vpn_gateway_id      = aws_vpn_gateway.main.id
  static_routes_only  = true

  tags = {
    Name = "${var.project_name}-vpn-connection"
  }
}

# VPN Connection Route
resource "aws_vpn_connection_route" "office" {
  vpn_connection_id      = aws_vpn_connection.main.id
  destination_cidr_block = var.onpremises_cidr
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description = "${var.project_name} Transit Gateway"

  tags = {
    Name = "${var.project_name}-tgw"
  }
}

# Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-tgw-attachment"
  }
}

# Network ACLs
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-private-nacl"
  }
}

resource "aws_network_acl_association" "private" {
  count = length(aws_subnet.private)

  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

data "aws_region" "current" {}
