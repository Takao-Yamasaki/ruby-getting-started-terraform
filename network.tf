# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Bastion用プライベートサブネット
resource "aws_subnet" "bastion" {
  count             = length(var.bastion_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.bastion_subnet_cidr[count.index]
  availability_zone = "ap-northeast-1a"

  tags = {
    Name        = "${var.project_name}-bastion-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private-Bastion"
  }
}

# RDS用プライベートサブネット
resource "aws_subnet" "rds" {
  count             = length(var.rds_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.rds_subnet_cidr[count.index]
  availability_zone = count.index == 0 ? "ap-northeast-1a" : "ap-northeast-1c"

  tags = {
    Name        = "${var.project_name}-rds-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private-RDS"
  }
}

# Bastion用プライベートルートテーブル
resource "aws_route_table" "bastion" {
  count  = length(var.bastion_subnet_cidr)
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-bastion-rt-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private-Bastion"
  }
}

# RDS用プライベートルートテーブル
resource "aws_route_table" "rds" {
  count  = length(var.rds_subnet_cidr)
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-rds-rt-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private-RDS"
  }
}

# Bastionサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "bastion" {
  count          = length(var.bastion_subnet_cidr)
  subnet_id      = aws_subnet.bastion[count.index].id
  route_table_id = aws_route_table.bastion[count.index].id
}

# RDSサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "rds" {
  count          = length(var.rds_subnet_cidr)
  subnet_id      = aws_subnet.rds[count.index].id
  route_table_id = aws_route_table.rds[count.index].id
}
