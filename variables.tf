variable "role_name" {
  description = "IAM role name for GitHub Actions"
  type        = string
}

variable "repositories" {
  description = "List of GitHub repositories allowed to assume the role"
  type        = list(string)
}

variable "attach_policies" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}
