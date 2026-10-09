locals {
  name = "${var.project}-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  name                       = local.name
  vpc_cidr                   = var.vpc_cidr
  az_count                   = 3
  single_nat_gateway         = var.single_nat_gateway
  enable_interface_endpoints = var.enable_interface_endpoints
}

# Security group for the ECS tasks. It lives here for now so the DB can
# reference it; it moves into the ecs-service module when we build that.
resource "aws_security_group" "app" {
  name_prefix = "${local.name}-app-"
  description = "ECS tasks (application tier)"
  vpc_id      = module.network.vpc_id

  tags = { Name = "${local.name}-app-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "app_all_out" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound (ECR, Secrets Manager, logs, DB)"
}

module "rds" {
  source = "../../modules/rds"

  name                         = local.name
  vpc_id                       = module.network.vpc_id
  subnet_ids                   = module.network.data_subnet_ids
  allowed_security_group_ids   = [aws_security_group.app.id]
  instance_class               = var.db_instance_class
  multi_az                     = var.db_multi_az
  deletion_protection          = var.db_deletion_protection
  skip_final_snapshot          = var.db_skip_final_snapshot
  backup_retention_period      = var.db_backup_retention_period
  performance_insights_enabled = var.db_performance_insights
}
