locals {
  role_name               = var.role_name != "" ? var.role_name : "${var.project_name}-github-actions-role"
  # rds_backup_bucket_name  = var.rds_backup_bucket_name != "" ? var.rds_backup_bucket_name : "${var.project_name}-rds-backup"
  repository_full_name    = "${var.github_org}/${var.github_repo}"
}

data "aws_caller_identity" "current" {}

module "github_oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "2.2.1"

  role_name        = local.role_name
  role_description = "Role for GitHub Actions OIDC - ${var.project_name}"
  repositories     = [local.repository_full_name]
}

# GitHubActionsロールにAdministratorAccessをアタッチ
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = local.role_name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

  depends_on = [module.github_oidc]
}

# CloudFrontキャッシュ削除専用GHAロール（最小権限）
resource "aws_iam_role" "github_actions_cloudfront" {
  name        = "${var.project_name}-gha-cloudfront-role"
  description = "Role for GitHub Actions to invalidate CloudFront cache"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${local.repository_full_name}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-gha-cloudfront-role"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [module.github_oidc]
}

# CloudFrontキャッシュ削除ポリシー（CreateInvalidationのみ）
resource "aws_iam_policy" "cloudfront_invalidation" {
  name        = "${var.project_name}-cloudfront-invalidation-policy"
  description = "Allow GitHub Actions to create CloudFront invalidations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = aws_cloudfront_distribution.staging.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_cloudfront" {
  role       = aws_iam_role.github_actions_cloudfront.name
  policy_arn = aws_iam_policy.cloudfront_invalidation.arn
}
