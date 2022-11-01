# -----------------------------------------------------------------------------
# ROOT TERRAGRUNT CONFIGURATION
#   Terragrunt is a thin wrapper for Terraform that provides extra tools for 
#   working with multiple Terraform modules, remote state, and locking: 
#
#       https://github.com/gruntwork-io/terragrunt
#
#   This HCL file serves as the "root" module, as in the terraform concept
#   of a root module being the one that binds connects all other modules
#   into the single entrypoint for the terraform process.
# -----------------------------------------------------------------------------

locals {

}

# Configure how Terragrunt interacts with Terraform
terraform {
  # THIS ROOT MODULE HAS NO SOURCE. IT JUST PROVIDES CONFIG AND VARS FOR ITS CHILDREN

  # Define common args to be applied to custom list of terraform commands.
  #   - Can be defined multiple times for different custom command groups.
  #   - extra_arguments for init command has special behavior and constraints:
  #     https://terragrunt.gruntwork.io/docs/features/keep-your-cli-flags-dry/#extra_arguments-for-init
  #   - Arguments elements cannot include whitespace, split list on space to 'insert' spoce in arg
  #       https://terragrunt.gruntwork.io/docs/features/keep-your-cli-flags-dry/#handling-whitespace
  # Force Terraform to not ask for input value if some variables are undefined.
  extra_arguments "disable_input" {
    commands  = get_terraform_commands_that_need_input()
    arguments = ["-input=false"]
  }
  extra_arguments "auto-approve" {
    commands  = ["apply", "destroy"]
    arguments = ["-auto-approve"]
  }
  # Force Terraform to keep trying to acquire a lock for up to 20 minutes if someone else already has the lock
  # extra_arguments "retry_lock" {
  #   commands  = get_terraform_commands_that_need_locking()
  #   arguments = ["-lock-timeout=20m"]
  # }
  # Force Terraform to run with reduced parallelism
  # extra_arguments "parallelism" {
  #   commands  = get_terraform_commands_that_need_parallelism()
  #   arguments = ["-parallelism=5"]
  # }
  # terraform commands that accept -var and -var-file parameters
  # extra_arguments "common_var" {
  #   commands  = get_terraform_commands_that_need_vars()
  #   arguments = ["-var-file=${get_aws_account_id()}.tfvars"]
  #   https://terragrunt.gruntwork.io/docs/features/keep-your-cli-flags-dry/#required-and-optional-var-files
  # }
  extra_arguments "prettier" {
    commands  = ["plan", "apply", "destroy"]
    arguments = ["-compact-warnings"]
  }
}

# DRY provider configuration to use for all terraform modules
#   * Generates provider.tf file for each module invoked
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
    # uses AWS_PROFILE and AWS_REGION, expected to be set correctly in shell
}
EOF
}

# DRY provider versions to use for all terraform modules
#   * Generates versions_override.tf file for each module invoked
#   * The providers below are only the ones common to all child modules
generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.36.1"
    }
  }
}
EOF
}

# DRY backend configuration to use for all terraform modules
#   * Generates backend.tf file for each module invoked
#   * Automatically sets key to relative path between the root terragrunt.hcl 
#     and the child module. This causes the folder structure within the 
#     Terraform state store (s3 bucket here) to  match your Terraform code 
#     folder structure.
#   * The remote_state block is for managing the remote state resources themselves (e.g. s3)
#     in addition to generating the backend configuration for modules that use them.
#     (This feature only exists for s3 and gcs at the moment:
#      https://terragrunt.gruntwork.io/docs/features/keep-your-remote-state-configuration-dry/#create-remote-state-and-locking-resources-automatically)
#   * Since we are managing our remote state resources outside of terragrunt (Makefile/cli),
#     here we use generate block to generate the backend configuration for our modules.
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "local" {
  # backend "s3" {
  #   bucket  = "${get_env("BACKEND_S3_BUCKET", "")}"
  #   # each child module stores its Terraform state at a different key in the bucket
  #   key     = "${path_relative_to_include()}/terraform.tfstate"
  #   region  = "${get_env("REGION", "")}"
  #   encrypt = true
  #   # role_arn       = "arn:aws:iam::${get_aws_account_id()}:role/terraform/TerraformBackend"
  #   dynamodb_table = "${get_env("BACKEND_DYNAMODB_TABLE", "")}"
  }
}
EOF
}
