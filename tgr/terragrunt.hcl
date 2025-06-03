# Configure the remote backend
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket = "my-tf-state-dasd723"

    key            = "tf.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}

# Configure the AWS provider
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "ap-southeast-1"
}
EOF
}

# Configure the module
#
# The URL used here is a shorthand for
# "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=5.16.0".
#
# You can find the module at:
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
#
# Note the extra `/` after the `tfr` protocol is required for the shorthand
# notation.
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