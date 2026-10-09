variable "name" {
  description = "Name prefix (e.g. myapp-prod). The ALB is named <name>-alb (32 char limit)."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  description = "Security group of the ECS tasks. The ALB is allowed to reach it on container_port."
  type        = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "certificate_arn" {
  description = "ACM certificate ARN. null = HTTP only on :80. Set it to enable HTTPS on :443 and redirect :80 to it."
  type        = string
  default     = null
}

variable "ingress_cidrs" {
  description = "Who may reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "deletion_protection" {
  type    = bool
  default = true
}
