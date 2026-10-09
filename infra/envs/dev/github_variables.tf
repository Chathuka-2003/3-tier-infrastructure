variable "github_repo" {
  description = "GitHub repository (owner/repo) whose pipeline may deploy to this environment."
  type        = string
  default     = "Chathuka-2003/3-tier-infrastructure"
}

variable "create_oidc_provider" {
  description = "false if this AWS account already has the GitHub OIDC provider."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  type    = string
  default = ""
}
