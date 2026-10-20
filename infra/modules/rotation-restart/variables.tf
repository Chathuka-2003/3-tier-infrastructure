variable "name" {
  description = "Name prefix (e.g. threetier-prod)."
  type        = string
}

variable "secret_arn" {
  description = "ARN of the RDS-managed database secret that rotates."
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "schedule_expression" {
  description = "How often to check whether the secret was rotated after the current deployment."
  type        = string
  default     = "rate(2 minutes)"
}

variable "alarm_topic_arn" {
  description = "SNS topic that receives an alert if the function errors."
  type        = string
}

variable "enable_error_alarm" {
  type    = bool
  default = true
}

variable "log_retention_days" {
  type    = number
  default = 14
}
