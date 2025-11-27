variable "path" {
  description = "Path to the directory containing files to deploy"
  type        = string
}

variable "bucket_name" {
  description = "Optional custom bucket name. If not provided, a unique name will be generated"
  type        = string
  default     = null
}

variable "ignore_files" {
  description = "List of file paths (relative to path) to ignore during deployment"
  type        = list(string)
  default     = []
}

variable "name_prefix" {
  description = "Prefix for generated resource names"
  type        = string
  default     = "static-site"
}

