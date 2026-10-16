# Cheap overrides for rehearsing the PROD code in a personal/free-tier account.
# Use:  terraform plan -var-file=practice.tfvars -var container_image=...
# Never use this file for the client's real environment.
single_nat_gateway         = true
enable_interface_endpoints = false

db_instance_class          = "db.t4g.micro"
db_multi_az                = false
db_backup_retention_period = 1
db_deletion_protection     = false
db_skip_final_snapshot     = true
db_performance_insights    = false

ecr_force_delete          = true
alb_deletion_protection   = false
enable_container_insights = false

ecs_desired_count = 1
ecs_min_capacity  = 1
ecs_max_capacity  = 2
