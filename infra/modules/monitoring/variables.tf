variable "name" {
  description = "Name prefix (e.g. threetier-dev)."
  type        = string
}

variable "alert_email" {
  description = "Email that receives alarm notifications. Empty = topic is created but nobody is subscribed."
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "db_instance_identifier" {
  type = string
}

variable "target_5xx_threshold" {
  description = "5xx responses from the app within 5 minutes that trigger an alarm."
  type        = number
  default     = 5
}

variable "response_time_seconds" {
  description = "Average target response time (seconds) that triggers an alarm."
  type        = number
  default     = 2
}

variable "ecs_cpu_threshold" {
  type    = number
  default = 85
}

variable "ecs_memory_threshold" {
  type    = number
  default = 85
}

variable "db_cpu_threshold" {
  type    = number
  default = 80
}

variable "db_free_storage_bytes" {
  description = "Alarm when free storage drops below this (default 2 GiB)."
  type        = number
  default     = 2147483648
}

variable "db_free_memory_bytes" {
  description = "Alarm when freeable memory drops below this (default 64 MiB)."
  type        = number
  default     = 67108864
}

variable "db_connections_threshold" {
  type    = number
  default = 60
}
