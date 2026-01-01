# RDS S3エクスポート用KMSキー
resource "aws_kms_key" "rds_s3_export" {
  description             = "KMS key for RDS S3 export encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project_name}-rds-s3-export-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

# KMSキーエイリアス
resource "aws_kms_alias" "rds_s3_export" {
  name          = "alias/${var.project_name}-rds-s3-export"
  target_key_id = aws_kms_key.rds_s3_export.key_id
}

# KMSキーポリシー
resource "aws_kms_key_policy" "rds_s3_export" {
  key_id = aws_kms_key.rds_s3_export.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow RDS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# 現在のAWSアカウント情報を取得
data "aws_caller_identity" "current" {}
