variable "name" {
  description = "Name prefix for all network resources (e.g. myapp-prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to span (2 or 3)."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "subnet_newbits" {
  description = "Extra bits added to the VPC CIDR for each subnet (8 turns a /16 into /24s)."
  type        = number
  default     = 8
}

variable "single_nat_gateway" {
  description = "true = one shared NAT gateway (cheaper, dev). false = one per AZ (highly available, prod)."
  type        = bool
  default     = false
}

variable "enable_interface_endpoints" {
  description = "Create VPC interface endpoints for ECR, CloudWatch Logs and Secrets Manager."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Retention for VPC flow logs in CloudWatch."
  type        = number
  default     = 30
}
