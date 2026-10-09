variable "container_image" {
  description = "Image to run. Starts as a public placeholder so the ALB -> ECS path can be tested before your app image exists."
  type        = string
  default     = "public.ecr.aws/docker/library/nginx:stable-alpine"
}

variable "container_port" {
  description = "Port the container listens on (80 for the nginx placeholder, 8080 for Spring Boot)."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB health check path (/ for the placeholder, /actuator/health for Spring Boot)."
  type        = string
  default     = "/"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. null = HTTP only."
  type        = string
  default     = null
}

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "ecs_min_capacity" {
  type    = number
  default = 1
}

variable "ecs_max_capacity" {
  type    = number
  default = 2
}
