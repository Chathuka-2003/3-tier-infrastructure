output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  value = module.network.app_subnet_ids
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "db_address" {
  value = module.rds.address
}

output "db_secret_arn" {
  value = module.rds.master_user_secret_arn
}
