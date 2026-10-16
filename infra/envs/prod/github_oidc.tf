module "github_oidc" {
  source = "../../modules/github-oidc"

  name                       = local.name
  github_repo                = var.github_repo
  create_oidc_provider       = var.create_oidc_provider
  existing_oidc_provider_arn = var.existing_oidc_provider_arn

  ecr_repository_arn = module.ecr.repository_arn
  ecs_cluster_name   = module.ecs.cluster_name
  ecs_service_name   = module.ecs.service_name
  task_role_arns     = [module.ecs.execution_role_arn, module.ecs.task_role_arn]
}
