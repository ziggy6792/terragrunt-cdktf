# param-store/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "dynamo" {
  config_path = "../dynamo"
}

terraform {
   source = "tfr:///terraform-aws-modules/ssm-parameter/aws?version=1.1.2"
}

inputs = {
  name  = "/my-app/dynamo-table-id"
  value = dependency.dynamo.outputs.dynamodb_table_id
  type  = "String"
}