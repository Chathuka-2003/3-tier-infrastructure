output "role_arn" {
  description = "Put this in the GitHub repo variable AWS_ROLE_ARN."
  value       = aws_iam_role.deploy.arn
}

output "oidc_provider_arn" {
  value = local.oidc_provider_arn
}
