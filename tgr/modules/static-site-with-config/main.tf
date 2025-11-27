locals {
  name_prefix = "tf-frontend-${var.stage}"
  # Automatically add config_file_path to ignore_files as it it not part of the frontend deployment
  ignore_files = concat(var.ignore_files, [var.config_file_path])
}

module "static_site" {
  source = "./static-site"

  path         = var.frontend_path
  ignore_files = local.ignore_files
  name_prefix  = local.name_prefix
}

# Add the config file to the S3 bucket
resource "aws_s3_object" "env_config" {
  bucket = module.static_site.bucket_id

  key           = var.config_file_path
  content       = jsonencode(var.frontend_config)
  content_type  = "application/json"
  force_destroy = true
}
