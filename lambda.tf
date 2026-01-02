# Lambda用のIAMロール
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# AWSLambdaBasicExecutionRoleをアタッチ
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda用のカスタムポリシー（RDSエクスポート用）
resource "aws_iam_role_policy" "lambda" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "rds:StartExportTask",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda関数のデプロイパッケージ作成
# Pythonファイルをzip形式にアーカイブしてLambdaにデプロイ可能な形式にする
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/rds_s3_export.py"
  output_path = "${path.module}/lambda/rds_s3_export.zip"
}

# Lambda関数
resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "rds_s3_export"
  role             = aws_iam_role.lambda.arn
  handler          = "rds_s3_export.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.11"
  
  environment {
    variables = {
      # RDSインスタンスの識別子
      DB_INSTANCE_IDENTIFIER = aws_db_instance.main.identifier
      # エクスポート先のS3バケット名
      S3_BUCKET_NAME = aws_s3_bucket.rds_backup.bucket
      # S3にエクスポート時に使用するIAMロールのARN
      IAM_ROLE_ARN = aws_iam_role.rds_backup.arn
      # 作成したKMSキーのARN
      KMS_KEY_ID = aws_kms_key.rds_backup.arn
    }
  }

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}
