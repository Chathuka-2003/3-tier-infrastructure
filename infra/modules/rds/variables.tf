variable "name" {
  description = "Name prefix (e.g. myapp-prod)."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Isolated data-tier subnet IDs (at least 2 AZs)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 3306 (the app tier)."
  type        = list(string)
}

variable "engine_version" {
  description = "MySQL engine version. Pin the exact minor in prod (check: aws rds describe-db-engine-versions --engine mysql)."
  type        = string
  default     = "8.4"
}

variable "parameter_group_family" {
  type    = string
  default = "mysql8.4"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.small"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling (GiB)."
  type        = number
  default     = 100
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "master_username" {
  type    = string
  default = "dbadmin"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 14
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "performance_insights_enabled" {
  description = "Not supported on the smallest burstable classes - disable for db.t4g.micro."
  type        = bool
  default     = true
}
