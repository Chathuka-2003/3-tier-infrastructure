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
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "enable_interface_endpoints" {
  type    = bool
  default = false
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "db_performance_insights" {
  type    = bool
  default = false
}

variable "db_backup_retention_period" {
  type    = number
  default = 1
}
