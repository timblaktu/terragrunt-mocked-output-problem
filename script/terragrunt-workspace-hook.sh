#!/bin/bash

# Implement before_hook to make terragrunt use terraform workspaces
#   https://github.com/gruntwork-io/terragrunt/issues/1581

export RED="$(tput setaf 1)"
export GREEN="$(tput setaf 2)"
export YELLOW="$(tput setaf 3)"
export RESET="$(tput sgr0)"
function indent {
    echo "${1}" | sed 's/^/    /'
}

# set -euo pipefail
MODULE_SPECIFIC_WORKSPACE=$1
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck disable=SC1090,SC1091
source "${SCRIPT_DIR}"/functions.sh
echo "terragrunt-workspace-hook: TF_WORKSPACE=${TF_WORKSPACE} MODULE_SPECIFIC_WORKSPACE=${MODULE_SPECIFIC_WORKSPACE}. Unsetting TF_WORKSPACE..."
unset TF_WORKSPACE
set +e
errf=$(mktemp)
echo "terragrunt-workspace-hook: Initializing using default workspace (unsetting TF_WORKSPACE)..."
TF_WORKSPACE= terraform init -upgrade -reconfigure > errf 2>&1
if [ $? -eq 0 ] ; then
    echo "$(indent "${GREEN}Default workspace initialized${RESET}")"
else
    echo "$(indent "${RED}Error $? initializing default workspace$(indent "$(<errf)")${RESET}")"
    exit 1
fi

echo "terragrunt-workspace-hook: Selecting the module-specific workspace ${MODULE_SPECIFIC_WORKSPACE}..."
terraform workspace select ${MODULE_SPECIFIC_WORKSPACE} > errf 2>&1
if [ $? -eq 0 ] ; then
    echo "$(indent "${GREEN}Workspace ${MODULE_SPECIFIC_WORKSPACE} selected${RESET}")"
else
    echo "$(indent "${RED}Error $? selecting workspace ${MODULE_SPECIFIC_WORKSPACE}$(indent "$(<errf)")${RESET}")"
    echo "terragrunt-workspace-hook: Creating the module-specific workspace ${MODULE_SPECIFIC_WORKSPACE}..."
    terraform workspace new ${MODULE_SPECIFIC_WORKSPACE} > errf 2>&1
    if [ $? -eq 0 ] ; then
        echo "$(indent "${GREEN}Workspace ${MODULE_SPECIFIC_WORKSPACE} created${RESET}")"
    else
        echo "$(indent "${RED}Error $? creating workspace ${MODULE_SPECIFIC_WORKSPACE}$(indent "$(<errf)")${RESET}")"
    fi
fi
if [ "${MODULE_SPECIFIC_WORKSPACE}" != "default" ] ; then
    echo "terragrunt-workspace-hook: Final initialization using module-specific workspace ${MODULE_SPECIFIC_WORKSPACE})..."
    terraform init -upgrade -reconfigure "${MODULE_SPECIFIC_WORKSPACE}"
    if [ $? -eq 0 ] ; then
        echo "$(indent "${GREEN}Workspace ${MODULE_SPECIFIC_WORKSPACE} initialized${RESET}")"
    else
        echo "$(indent "${RED}Error $? initializing workspace ${MODULE_SPECIFIC_WORKSPACE}$(indent "$(<errf)")${RESET}")"
    fi
fi
