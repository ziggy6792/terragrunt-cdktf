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
  description = "Additional list of file paths (relative to frontend_path) to ignore during deployment. The config_file_path will be automatically added."
  type        = list(string)
  default     = []
}

variable "config_file_path" {
  description = "Path (relative to bucket root) where the frontend config JSON file will be stored"
  type        = string
  default     = "config/env.json"
}

