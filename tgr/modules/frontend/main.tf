provider "aws" {
  region = var.region
}

locals {
  name_prefix = "tf-frontend-${var.stage}"
}

module "static_site" {
  source = "../static-site"

  path         = var.frontend_path
  ignore_files = var.ignore_files
  name_prefix  = local.name_prefix
}

resource "aws_s3_object" "env_config" {
  bucket = module.static_site.bucket_id

  key           = "config/env.json"
  content       = jsonencode(var.frontend_config)
  content_type  = "application/json"
  force_destroy = true
}

