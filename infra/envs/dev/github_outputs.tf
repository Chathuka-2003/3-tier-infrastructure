output "github_actions_role_arn" {
  description = "Set as the AWS_ROLE_ARN variable in the GitHub repo."
  value       = module.github_oidc.role_arn
}
