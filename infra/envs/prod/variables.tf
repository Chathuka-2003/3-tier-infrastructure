# ---------------------------------------------------------------- General
variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "project" {
  type    = string
  default = "threetier"
}

variable "environment" {
  type    = string
  default = "prod"
}

# ---------------------------------------------------------------- Network (production defaults)
variable "vpc_cidr" {
  description = "Different from dev (10.0.0.0/16) so the two can be peered later."
  type        = string
  default     = "10.1.0.0/16"
}

variable "az_count" {
  type    = number
  default = 3
}

variable "single_nat_gateway" {
  description = "false = one NAT gateway per AZ (survives an AZ failure)."
  type        = bool
  default     = false
}

variable "enable_interface_endpoints" {
  description = "Private access to ECR, CloudWatch Logs and Secrets Manager without going through NAT."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------- Database
variable "db_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "db_multi_az" {
  type    = bool
  default = true
}

variable "db_backup_retention_period" {
  description = "Days of automated backups. Values above 1 need a paid AWS account plan."
  type        = number
  default     = 14
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "db_performance_insights" {
  type    = bool
  default = true
}

# ---------------------------------------------------------------- Application
variable "container_image" {
  description = "Image to run, e.g. <account>.dkr.ecr.<region>.amazonaws.com/threetier-prod-app:<tag>. Required: push an image first (see README)."
  type        = string
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "health_check_path" {
  type    = string
  default = "/actuator/health"
}

variable "ecs_cpu" {
  type    = number
  default = 512
}

variable "ecs_memory" {
  type    = number
  default = 1024
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}

variable "ecs_min_capacity" {
  type    = number
  default = 2
}

variable "ecs_max_capacity" {
  type    = number
  default = 6
}

variable "enable_container_insights" {
  type    = bool
  default = true
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "ecr_force_delete" {
  type    = bool
  default = false
}

variable "alb_deletion_protection" {
  type    = bool
  default = true
}

variable "certificate_arn" {
  description = "ACM certificate for HTTPS. null = HTTP only, which is NOT acceptable for real production traffic."
  type        = string
  default     = null
}

# ---------------------------------------------------------------- Monitoring and CI/CD
variable "alert_email" {
  type    = string
  default = ""
}

variable "github_repo" {
  description = "owner/repo whose main-branch pipeline may deploy."
  type        = string
  default     = "Chathuka-2003/3-tier-infrastructure"
}

variable "create_oidc_provider" {
  description = "false if the AWS account already has the GitHub OIDC provider."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  type    = string
  default = ""
}
