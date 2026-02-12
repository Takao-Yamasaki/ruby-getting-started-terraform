# OpenSearch

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# OpenSearch用プライベートサブネット
resource "aws_subnet" "opensearch" {
  count             = length(var.opensearch_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.opensearch_subnet_cidr[count.index]
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name        = "${var.project_name}-opensearch-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private-OpenSearch"
  }
}

# OpenSearch用プライベートルートテーブル
resource "aws_route_table" "opensearch" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-opensearch-rt"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Private-OpenSearch"
  }
}

# OpenSearchサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "opensearch" {
  count          = length(var.opensearch_subnet_cidr)
  subnet_id      = aws_subnet.opensearch[count.index].id
  route_table_id = aws_route_table.opensearch.id
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

resource "aws_opensearch_domain" "opensearch" {
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/ruby-getting-started/*"
      }
    ]
  })

  advanced_options = {
    "indices.fielddata.cache.size"        = "20"
    "indices.query.bool.max_clause_count" = "1024"
  }

  domain_name    = "ruby-getting-started"
  engine_version = "OpenSearch_3.3"

  advanced_security_options {
    anonymous_auth_enabled         = false
    enabled                        = true
    internal_user_database_enabled = true
  }

  cluster_config {
    instance_count = 1
    instance_type  = "t3.small.search"
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  ebs_options {
    ebs_enabled = true
    iops        = 3000
    throughput  = 125
    volume_size = 10
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.opensearch.arn
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    security_group_ids = [aws_security_group.opensearch.id]
    subnet_ids         = aws_subnet.opensearch[*].id
  }
}
