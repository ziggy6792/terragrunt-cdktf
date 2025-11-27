# static-site/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env = include.root.locals.env
}

terraform {
  source = "${include.root.locals.module_dir}/frontend"
}

inputs = {
  frontend_path = "../frontend/dist"  # Update this path to your actual frontend build directory
  frontend_config = {
    CDKTF_API_URL = "https://api-dev.example.com"
    # Add more config properties here as needed
  }
  region        = "ap-southeast-1"
  stage         = local.env
  ignore_files  = ["config/env.json"]
}

