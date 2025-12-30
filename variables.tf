variable "project_name" {
  description = "Project name used as a prefix for resource naming"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "role_name" {
  description = "IAM role name for GitHub Actions (defaults to project_name-github-actions-role)"
  type        = string
  default     = ""
}

variable "attach_policies" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "rds_backup_bucket_name" {
  description = "S3 bucket name for RDS backups (defaults to project_name-rds-backup)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "production"
}

variable "backup_retention_days" {
  description = "Number of days to retain RDS backups in S3"
  type        = number
  default     = 365
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "bastion_subnet_cidr" {
  description = "CIDR blocks for bastion subnet"
  type        = list(string)
  default     = ["192.168.11.0/24"]
}

variable "rds_subnet_cidr" {
  description = "CIDR blocks for RDS subnet"
  type        = list(string)
  default     = ["192.168.21.0/24"]
}
