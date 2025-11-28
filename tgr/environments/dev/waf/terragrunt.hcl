# waf/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env = include.root.locals.env
}

terraform {
  source = "${include.root.locals.module_dir}/waf"
}

inputs = {
  name_prefix = "tf-frontend-${local.env}"
}

