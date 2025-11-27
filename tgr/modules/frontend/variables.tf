variable "frontend_path" {
  description = "Path to the frontend build directory"
  type        = string
}

variable "frontend_config" {
  description = "Frontend configuration object that will be written to config/env.json"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "stage" {
  description = "Deployment stage (e.g., dev, prod)"
  type        = string
}

variable "ignore_files" {
  description = "List of file paths (relative to frontend_path) to ignore during deployment"
  type        = list(string)
  default     = ["config/env.json"]
}

