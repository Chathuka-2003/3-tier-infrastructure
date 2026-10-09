variable "name" {
  description = "Repository name (e.g. myapp-prod-app)."
  type        = string
}

variable "force_delete" {
  description = "Allow terraform destroy to delete the repo even if it contains images (dev only)."
  type        = bool
  default     = false
}

variable "keep_last_images" {
  description = "How many images to keep; older ones are expired."
  type        = number
  default     = 20
}
