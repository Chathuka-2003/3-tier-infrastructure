# Restarts the ECS tasks after the RDS-managed secret rotates, so they never hold a stale password.
module "rotation_restart" {
  source = "../../modules/rotation-restart"

  name            = local.name
  secret_arn      = module.rds.master_user_secret_arn
  cluster_name    = module.ecs.cluster_name
  service_name    = module.ecs.service_name
  alarm_topic_arn = module.monitoring.sns_topic_arn
}
