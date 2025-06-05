# root.hcl

locals {
  root_dir = get_repo_root()
  env_hcl  = find_in_parent_folders("env.hcl")
  env      = read_terragrunt_config(local.env_hcl).locals.env
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket         = "my-tf-state-dasd723"
    key            = "${path_relative_to_include()}/tf.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-southeast-1"
}
EOF
}
