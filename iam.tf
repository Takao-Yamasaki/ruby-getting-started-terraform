locals {
  role_name               = var.role_name != "" ? var.role_name : "${var.project_name}-github-actions-role"
  rds_backup_bucket_name  = var.rds_backup_bucket_name != "" ? var.rds_backup_bucket_name : "${var.project_name}-rds-backup-20251230"
  repository_full_name    = "${var.github_org}/${var.github_repo}"
}

module "github_oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "2.2.1"

  role_name                 = local.role_name
  role_description          = "Role for GitHub Actions OIDC - ${var.project_name}"
  repositories              = [local.repository_full_name]
  oidc_role_attach_policies = var.attach_policies
}

# Secrets Manager用のポリシー
resource "aws_iam_policy" "secrets_manager" {
  name        = "${var.project_name}-secrets-manager-policy"
  description = "Allow GitHub Actions to manage Secrets Manager secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource"
        ]
        Resource = "arn:aws:secretsmanager:ap-northeast-1:*:secret:${var.project_name}-*"
      }
    ]
  })
}

# GitHubActionsロールにSecrets Managerポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "github_actions_secrets_manager" {
  role       = local.role_name
  policy_arn = aws_iam_policy.secrets_manager.arn
}
