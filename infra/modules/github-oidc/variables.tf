variable "name" {
  description = "Name prefix (e.g. threetier-dev)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository allowed to deploy, as owner/repo."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repo))
    error_message = "github_repo must look like owner/repo."
  }
}

variable "branch" {
  description = "Only workflows running on this branch may assume the role."
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if the AWS account already has one (only one per account is allowed)."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider, used when create_oidc_provider = false."
  type        = string
  default     = ""
}

variable "ecr_repository_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "task_role_arns" {
  description = "ECS execution + task role ARNs the pipeline may pass to ECS when registering a task definition."
  type        = list(string)
}
