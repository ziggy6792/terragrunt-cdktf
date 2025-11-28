# static-site/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env = include.root.locals.env
}

dependency "waf" {
  config_path = "../waf"
  skip_outputs = false
}

terraform {
  source = "${include.root.locals.module_dir}/static-site-with-config"
}

inputs = {
  frontend_path = "${get_repo_root()}/out/dist"
  frontend_config = {
    CDKTF_API_URL = "https://api-dev.example.com"
    # Add more config properties here as needed
  }
  region = "ap-southeast-1"
  stage  = local.env
  web_acl_id = dependency.waf.outputs.web_acl_arn
  # ignore_files is optional - config_file_path is automatically ignored
}

