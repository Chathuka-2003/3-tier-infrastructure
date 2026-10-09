variable "name" {
  type = string
}

variable "subnet_ids" {
  description = "Private app-tier subnets."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the tasks."
  type        = string
}

variable "target_group_arn" {
  type = string
}

variable "alb_resource_label" {
  description = "<alb arn_suffix>/<target group arn_suffix>, used by request-count autoscaling."
  type        = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64. Must match the architecture the image was built for."
  type        = string
  default     = "X86_64"
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 6
}

variable "cpu_target" {
  description = "Target average CPU % for autoscaling."
  type        = number
  default     = 60
}

variable "requests_per_target" {
  description = "Target ALB requests per task per minute for autoscaling."
  type        = number
  default     = 1000
}

variable "environment" {
  description = "Plain environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Env var name => Secrets Manager valueFrom (arn or arn:json-key::)."
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Secrets the task execution role may read."
  type        = list(string)
  default     = []
}

variable "kms_key_arns" {
  description = "KMS keys that encrypt those secrets (execution role gets kms:Decrypt)."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_container_insights" {
  type    = bool
  default = true
}

variable "health_check_grace_period" {
  description = "Seconds ECS ignores failing ALB health checks after a task starts (Spring Boot needs time)."
  type        = number
  default     = 90
}
