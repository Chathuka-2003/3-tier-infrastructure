# Tier 1 (ALB) + Tier 2 (ECS) + registry.

module "ecr" {
  source = "../../modules/ecr"

  name         = "${local.name}-app"
  force_delete = var.ecr_force_delete
}

module "alb" {
  source = "../../modules/alb"

  name                  = local.name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  app_security_group_id = aws_security_group.app.id
  container_port        = var.container_port
  health_check_path     = var.health_check_path
  certificate_arn       = var.certificate_arn
  deletion_protection   = var.alb_deletion_protection
}

module "ecs" {
  source = "../../modules/ecs"

  name               = local.name
  subnet_ids         = module.network.app_subnet_ids
  security_group_id  = aws_security_group.app.id
  target_group_arn   = module.alb.target_group_arn
  alb_resource_label = "${module.alb.arn_suffix}/${module.alb.target_group_arn_suffix}"

  container_image = var.container_image
  container_port  = var.container_port

  cpu                       = var.ecs_cpu
  memory                    = var.ecs_memory
  health_check_grace_period = 180

  desired_count = var.ecs_desired_count
  min_capacity  = var.ecs_min_capacity
  max_capacity  = var.ecs_max_capacity

  enable_container_insights = var.enable_container_insights
  log_retention_days        = var.log_retention_days

  environment = {
    SPRING_DATASOURCE_URL = "jdbc:mysql://${module.rds.address}:${module.rds.port}/${module.rds.db_name}"
  }

  secrets = {
    SPRING_DATASOURCE_USERNAME = "${module.rds.master_user_secret_arn}:username::"
    SPRING_DATASOURCE_PASSWORD = "${module.rds.master_user_secret_arn}:password::"
  }

  secret_arns  = [module.rds.master_user_secret_arn]
  kms_key_arns = [module.rds.kms_key_arn]

  depends_on = [module.alb]
}
