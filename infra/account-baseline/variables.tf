variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "name" {
  description = "Prefix for resource names."
  type        = string
  default     = "baseline"
}

variable "alert_email" {
  description = "Receives budget alerts and GuardDuty findings (AWS sends a confirmation link)."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget in USD. Alerts at 80% actual and 100% forecast."
  type        = number
  default     = 100
}

variable "create_cloudtrail" {
  description = "Create a multi-region CloudTrail. Set false if the account already has the trail you want."
  type        = bool
  default     = true
}

variable "trail_retention_days" {
  description = "How long CloudTrail logs are kept in S3."
  type        = number
  default     = 365
}

variable "cloudtrail_force_destroy" {
  description = "Allow terraform destroy to delete the log bucket even if it contains logs (practice only)."
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable GuardDuty in this region. Set false if a detector already exists (only one is allowed per region)."
  type        = bool
  default     = true
}

variable "block_s3_public_access" {
  description = "Block public access to ALL S3 buckets in the account."
  type        = bool
  default     = true
}
