#!/usr/bin/env bash
set -euo pipefail

#################################################################################
#Script Name    :create-skeleton.sh
#Description    :create the skeleton of scripts with different configuration
#                options
#Args           :
#Author         :Pablo Acereda
#Email          :p.aceredag@gmail.com
#################################################################################

# Defaults
REPO_NAME=""
OWNER=""
TECHNOLOGIES=[]
DEPENDABOT=0 # false
FORCE_PR=0 # false

function help() {
  echo "NAME"
  echo "    create-skeleton.sh"
  echo "SYNOPSIS"
  echo "    create-skeleton [options]"
  echo "DESCRIPTION"
  echo "    Script that facilitates creating a repository skeleton."
  echo "OPTIONS"
  echo "    -n, --name <repository-name>"
  echo "        Mandatory. Name of the repository."
  echo "    -o, --owner <repository-owner>"
  echo "        Mandatory. GitHub owner of the repository. NOTE: Must have permissions to create the repository for this owner."
  echo "    -d, --activate-dependabot"
  echo "        Activate Dependabot dependency analysis."
  echo "    -p, --force-pr-contribution"
  echo "        For using PRs for code contributions, no code can be pushed to master branch."
  echo "    -f, --file"
  echo "        File configuration of this script."
  echo "EXAMPLES"
  echo "    create-skeleton.sh --help"
  echo "        To better know how this script works."
  echo "    create-skeleton.sh --name myRepoSkeleton --owner PabloAceG"
  echo "        Create a plain repository with no technologies called 'myRepoSkeleton' being the owner 'PabloAceG'."
  echo "AUTHORS"
  echo "    - Pablo Acereda <p.aceredag@gmail.com>"
  exit 0
}

function get_parameters() {
  while [ "$#" -gt 0 ]
  do
    case "$1" in
      --name | -n)
        shift
        REPO_NAME=$1
        ;;
      --owner | -o)
        shift
        OWNER=$1
      ;;
      --activate-dependabot | -d)
        DEPENDABOT=1
      ;;
      --force-pr-contribution | -p)
        FORCE_PR=1
      ;;
      --file | -f)
          echo "Using a file for configuration is still on the making."
          echo "Try --help command to see how to configure the options manually."
          exit 0
      ;;
      --help | -h)
        help
      ;;
      *)
        echo "[ERROR]: $param is not recognized as a valid argument. Run --help command to see valid arguments."
        exit 1
      ;;
    esac
    shift # Iterate to next parameter
  done
}

function create_repo() {
    get_parameters "$@"
}

create_repo "$@"
