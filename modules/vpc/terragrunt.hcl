# Include root terragrunt config to pick up generated backend, providers, etc.
include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/terraform-aws-modules//terraform-aws-vpc?ref=v3.18.0"

  # Make terragrunt use terraform workspaces. https://github.com/gruntwork-io/terragrunt/issues/1581
  #   This module is designed to create a complete set of infrastructure 
  #   in a distinct environment isolated by terraform workspace. For this reason,
  #   here we pass $ENVIRONMENT to the before_hook to select the terraform workspace
  #   specified by the user.
  before_hook "workspace" {
    commands = ["init", "fmt", "validate", "plan", "apply", "destroy", "refresh", "show", "state", "output", "graph"]
    execute = [
      "../../script/terragrunt-workspace-hook.sh",
      "${get_env("ENVIRONMENT")}"
    ]
  }
}

locals {
  # Load variables from an hcl configuration file defined at root
  globals = read_terragrunt_config(find_in_parent_folders("globals.hcl"))
  # TODO: this should come from input variable, spec by account/env-specific tfvars/hcl
  vpc_cidr = "10.0.0.0/16"
}

dependency "region_data" {
  config_path = "../region/data"
  # Mock Outputs allow running "local commands" like plan, fmt, validate without deployed resources
  # These values are used as inputs if target config hasn’t been applied yet.
  #   https://terragrunt.gruntwork.io/docs/features/execute-terraform-commands-on-multiple-modules-at-once/#unapplied-dependency-and-mock-outputs
  # See this issue comment for details on mocking dep outputs:
  #   https://github.com/gruntwork-io/terragrunt/issues/940#issuecomment-610108712
  mock_outputs = {
    name                    = "us-west-2"
    availability_zone_names = ["foo", "bar"]
  }
  skip_outputs = true
  mock_outputs_allowed_terraform_commands = ["fmt", "validate"]
  mock_outputs_merge_strategy_with_state  = "deep_map_only" # no_merge (default), shallow, deep_map_only
  # skip_outputs means “use mocks all the time if they are set”
}

inputs = {
  name = "${local.globals.inputs.cicd_env_name}"
  cidr = local.vpc_cidr

  # TODO: make these region-resilient. All regions don't have 3 AZs, so check N before slicing N from the list
  azs             = slice(dependency.region_data.outputs.availability_zone_names, 0, 2)
  public_subnets  = [for k, v in slice(dependency.region_data.outputs.availability_zone_names, 0, 2) : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in slice(dependency.region_data.outputs.availability_zone_names, 0, 2) : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Manage so we can name
  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.globals.inputs.cicd_env_name}-default" }
  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.globals.inputs.cicd_env_name}-default" }

  # TODO: make this false and create SG outside module and pass in to workaround
  #       bug/race condition caused by leaky CNI/SG, like this:
  #   https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/283#issuecomment-914758128
  manage_default_security_group = true

  default_security_group_tags = { Name = "${local.globals.inputs.cicd_env_name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.globals.inputs.cicd_env_name}" = "shared"
    "kubernetes.io/role/elb"                                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.globals.inputs.cicd_env_name}" = "shared"
    "kubernetes.io/role/internal-elb"                             = 1
  }

  # not sure from where tags appears so I commented definition
  #tags = local.tags
}
