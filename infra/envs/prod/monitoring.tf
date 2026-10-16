module "monitoring" {
  source = "../../modules/monitoring"

  name        = local.name
  alert_email = var.alert_email

  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  db_instance_identifier  = module.rds.db_instance_identifier
}
