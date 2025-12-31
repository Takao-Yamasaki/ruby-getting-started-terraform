# EventBridge Scheduler用IAMロール
resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-scheduler-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Scheduler用ポリシー（EC2とRDSの停止権限）
resource "aws_iam_role_policy" "scheduler" {
  name = "${var.project_name}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "rds:StopDBInstance"
        ]
        Resource = "*"
      }
    ]
  })
}

# EC2停止スケジュール（毎晩23時JST = 14時UTC）
resource "aws_scheduler_schedule" "stop_bastion" {
  name = "${var.project_name}-stop-bastion"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 14 * * ? *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = [aws_instance.bastion.id]
    })
  }

  description = "Stop Bastion EC2 instance at 23:00 JST daily"
}

# RDS停止スケジュール（毎晩23時JST = 14時UTC）
resource "aws_scheduler_schedule" "stop_rds" {
  name = "${var.project_name}-stop-rds"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 14 * * ? *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      DbInstanceIdentifier = aws_db_instance.main.identifier
    })
  }

  description = "Stop RDS instance at 23:00 JST daily"
}
