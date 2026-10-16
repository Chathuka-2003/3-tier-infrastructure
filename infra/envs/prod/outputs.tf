output "alb_dns_name" {
  value = module.alb.dns_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "db_address" {
  value = module.rds.address
}

output "db_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}

output "dashboard_name" {
  value = module.monitoring.dashboard_name
}
