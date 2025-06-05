# dynamo/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env = include.root.locals.env
}

terraform {
  source = "${include.root.locals.module_dir}/dynamodb-table"
}

inputs = {
  name         = "${local.env}-my-dynamodb-table"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]
}

