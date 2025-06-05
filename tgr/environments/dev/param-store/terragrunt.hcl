# param-store/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env = include.root.locals.env
}

dependency "dynamo" {
  config_path = "../dynamo"
}

terraform {
   source = "${get_repo_root()}/tgr/modules//param-store"
   
}

inputs = {
  name  = "/my-app/${local.env}/dynamo-table-id"
  value = dependency.dynamo.outputs.dynamodb_table_id
  type  = "String"
}