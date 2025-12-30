# 最新のAmazon Linux 2023 AMIを取得
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion用セキュリティグループ
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-bastion-sg-"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  # アウトバウンドルール（VPC内のRDSへの接続を許可）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow all outbound traffic within VPC"
  }

  tags = {
    Name        = "${var.project_name}-bastion-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Bastion用IAMロール
resource "aws_iam_role" "bastion" {
  name_prefix = "${var.project_name}-bastion-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-bastion-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SSM用マネージドポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Bastion用インスタンスプロファイル
resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "${var.project_name}-bastion-profile-"
  role        = aws_iam_role.bastion.name

  tags = {
    Name        = "${var.project_name}-bastion-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Bastion EC2インスタンス
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.bastion[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-bastion"
    Environment = var.environment
    Project     = var.project_name
  }
}
