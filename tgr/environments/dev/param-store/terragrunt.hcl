# param-store/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "dynamo" {
  config_path = "../dynamo"
}

terraform {
   source = "../../../modules/param-store"
}

inputs = {
  name  = "/my-app/dynamo-table-id"
  value = dependency.dynamo.outputs.dynamodb_table_id
  type  = "String"
}