# RDS用セキュリティグループ
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.main.id

  # Bastionからの接続を許可
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "Allow MySQL access from bastion"
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDSサブネットグループ
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = aws_subnet.rds[*].id

  tags = {
    Name        = "${var.project_name}-rds-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDSインスタンス
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-mysql"

  # エンジン設定
  engine         = "mysql"
  engine_version = "8.0.39"

  # インスタンススペック
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # データベース設定
  db_name  = replace(var.project_name, "-", "_")
  username = "admin"
  password = random_password.rds_password.result

  # ネットワーク設定
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # バックアップ設定
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  skip_final_snapshot     = true

  # パフォーマンス設定
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name        = "${var.project_name}-mysql"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDSパスワード（ランダム生成）
resource "random_password" "rds_password" {
  length  = 16
  special = true
}

# パスワードをSecrets Managerに保存
resource "aws_secretsmanager_secret" "rds_password" {
  name        = "${var.project_name}-rds-password"
  description = "RDS master password"

  tags = {
    Name        = "${var.project_name}-rds-password"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.rds_password.result
    engine   = "mysql"
    host     = aws_db_instance.main.endpoint
    port     = 3306
    dbname   = aws_db_instance.main.db_name
  })
}

# RDS S3エクスポート用IAMロール
resource "aws_iam_role" "rds_s3_export" {
  name = "${var.project_name}-rds-s3-export-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-rds-s3-export-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# RDS S3エクスポート用ポリシー
resource "aws_iam_role_policy" "rds_s3_export" {
  name = "${var.project_name}-rds-s3-export-policy"
  role = aws_iam_role.rds_s3_export.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.rds_backup.arn,
          "${aws_s3_bucket.rds_backup.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.rds_s3_export.arn
      }
    ]
  })
}
