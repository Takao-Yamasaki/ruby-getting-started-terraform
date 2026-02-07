# OpenSearch

# OpenSearch用プライベートサブネット
resource "aws_subnet" "opensearch" {
  count             = length(var.opensearch_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.opensearch_subnet_cidr[count.index]
  availability_zone = count.index == 0 ? "ap-northeast-1a" : "ap-northeast-1c"

  tags = {
    Name        = "${var.project_name}-opensearch-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private-OpenSearch"
  }
}

# OpenSearch用セキュリティグループ
resource "aws_security_group" "opensearch" {
  name        = "${var.project_name}-opensearch-sg"
  description = "Security group for OpenSearch domain"
  vpc_id      = aws_vpc.main.id

  # 踏み台からのHTTPS接続を許可
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "Allow HTTPS from bastion"
  }

  # アウトバウンドルール
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-opensearch-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}
