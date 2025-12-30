project_name    = "ruby-getting-started"
github_org      = "Takao-Yamasaki"
github_repo     = "ruby-getting-started-terraform"
role_name       = "ruby-getting-started-terraform-github-actions-role"
attach_policies = [
  "arn:aws:iam::aws:policy/IAMFullAccess",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AmazonVPCFullAccess",
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
]
