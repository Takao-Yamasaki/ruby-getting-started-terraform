# RDSバックアップ用S3バケット
resource "aws_s3_bucket" "rds_backup" {
  bucket = local.rds_backup_bucket_name

  tags = {
    Name        = "${var.project_name} RDS Backup Bucket"
    Purpose     = "RDS Database Backups"
    Environment = var.environment
    Project     = var.project_name
  }
}

# S3バケットバージョニング
resource "aws_s3_bucket_versioning" "rds_backup" {
  bucket = aws_s3_bucket.rds_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケット暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "rds_backup" {
  bucket = aws_s3_bucket.rds_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3バケットパブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "rds_backup" {
  bucket = aws_s3_bucket.rds_backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3バケットライフサイクルポリシー
resource "aws_s3_bucket_lifecycle_configuration" "rds_backup" {
  bucket = aws_s3_bucket.rds_backup.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.backup_retention_days
    }
  }
}

# RDS用S3バケットポリシー
resource "aws_s3_bucket_policy" "rds_backup" {
  bucket = aws_s3_bucket.rds_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSToWriteBackups"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.rds_backup.arn}/*"
      },
      {
        Sid    = "AllowRDSToListBucket"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.rds_backup.arn
      }
    ]
  })
}
