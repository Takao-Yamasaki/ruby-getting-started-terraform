module "github_oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "2.2.1"

  role_name                 = var.role_name
  role_description          = "Role for GitHub Actions OIDC"
  repositories              = var.repositories
  oidc_role_attach_policies = var.attach_policies
}
