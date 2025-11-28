locals {
  name_prefix = "tf-frontend-${var.stage}"
  # Automatically add config_file_path to ignore_files as it it not part of the frontend deployment
  ignore_files = concat(var.ignore_files, [var.config_file_path])
}

# Create WAF if enabled and no web_acl_id provided
module "waf" {
  count  = var.create_waf && var.web_acl_id == null ? 1 : 0
  source = "./waf"

  name_prefix = local.name_prefix

  # Pass the us-east-1 provider for CloudFront WAF (must be in us-east-1)
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

locals {
  # Determine web_acl_id to pass to static_site module
  web_acl_id_to_use = var.web_acl_id != null ? var.web_acl_id : (var.create_waf && length(module.waf) > 0 ? module.waf[0].web_acl_arn : null)
}

module "static_site" {
  source = "./static-site"

  path                      = var.frontend_path
  ignore_files              = local.ignore_files
  name_prefix               = local.name_prefix
  web_acl_id                = local.web_acl_id_to_use
  geo_restriction_type      = var.geo_restriction_type
  geo_restriction_locations = var.geo_restriction_locations
  enable_origin_failover    = var.enable_origin_failover
}

# Add the config file to the S3 bucket
resource "aws_s3_object" "env_config" {
  bucket = module.static_site.bucket_id

  key           = var.config_file_path
  content       = jsonencode(var.frontend_config)
  content_type  = "application/json"
  force_destroy = true
}

# Add the config file to the failover bucket if origin failover is enabled
resource "aws_s3_object" "env_config_failover" {
  count = var.enable_origin_failover ? 1 : 0

  bucket = module.static_site.failover_bucket_id

  key           = var.config_file_path
  content       = jsonencode(var.frontend_config)
  content_type  = "application/json"
  force_destroy = true
}
