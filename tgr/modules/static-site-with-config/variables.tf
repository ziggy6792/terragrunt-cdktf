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

variable "web_acl_id" {
  description = "Optional AWS WAF Web ACL ID to associate with CloudFront distribution. If not provided, a basic WAF will be created."
  type        = string
  default     = null
}

variable "create_waf" {
  description = "Whether to create a WAF Web ACL for CloudFront (if web_acl_id is not provided)"
  type        = bool
  default     = true
}

variable "geo_restriction_type" {
  description = "Geo restriction type: 'none', 'whitelist', or 'blacklist'"
  type        = string
  default     = "whitelist"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction (required if restriction_type is whitelist or blacklist)"
  type        = list(string)
  default     = ["US", "CA", "GB", "AU", "NZ", "IE"]
}

variable "enable_origin_failover" {
  description = "Enable origin failover with a secondary S3 bucket (for CKV_AWS_310 compliance)"
  type        = bool
  default     = true
}

