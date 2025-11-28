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

variable "web_acl_id" {
  description = "Optional AWS WAF Web ACL ID to associate with CloudFront distribution"
  type        = string
  default     = null
}

variable "geo_restriction_type" {
  description = "Geo restriction type: 'none', 'whitelist', or 'blacklist'"
  type        = string
  default     = "whitelist"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction (required if restriction_type is whitelist or blacklist)"
  type        = list(string)
  default     = ["US", "CA", "GB", "AU", "NZ", "IE"] # Default to common English-speaking countries
}

