# Global variables
#   Child modules that need to reference these do so by reading this config:
#   in their terraform.hcl with:
#     locals {
#       globals = read_terragrunt_config(find_in_parent_folders("globals.hcl"))
#     }
#   The above child module would then refer to the variables in the globals
#   map using e.g. local.globals.inputs.cicd_env_name
#
#   References:
#   - https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#read_terragrunt_config

inputs = {
  # Unique Prefix for this "CI/CD Environment".
  # The VPC is currently the outermost containing layer of one of what we call
  # "CI/CD Environments", which includes VPC, EKS, and K8s layers. All of
  # these modules tag their resources using this unique prefix that includes the
  # terraform workspace name to identify and disambiguate the different 
  # manifestations of these resources in the same account and region.
  # This Environment/Workspace name comes in through the Make arg/env var TF_WORKSPACE.
  cicd_env_name = join("-", [basename(get_parent_terragrunt_dir()), get_env("TF_WORKSPACE")])
}
