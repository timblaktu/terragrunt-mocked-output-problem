# Include root terragrunt config to pick up generated backend, providers, etc.
include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../..//modules/region/data"
  # Make terragrunt use terraform workspaces. https://github.com/gruntwork-io/terragrunt/issues/1581
  #   This module is designed to create singleton data sources at the regional level 
  #   that are shared within the current region in the current account.
  #   For this reason, here we pass "default" to the before_hook to select the "default"
  #   terraform workspace, so that the state of these singleton data sources will be managed
  #   in a single regional backend location.
  before_hook "workspace" {
    commands = ["init", "fmt", "validate", "plan", "apply", "destroy", "refresh", "show", "state", "output", "graph"]
    execute = [
      "../../../script/terragrunt-workspace-hook.sh",
      "default"
    ]
  }
}
# no dependencies, no inputs. This module only provides data source outputs
