# dynamo/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/dynamodb-table/aws?version=4.4.0"
}

inputs = {
  name         = "my-dynamodb-table"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]
}

