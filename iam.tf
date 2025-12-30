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
