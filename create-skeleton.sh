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
DEPENDABOT=false    # Don't activate Dependabot.
FORCE_PR=false      # Don't for PRs for contributions.
PUSH=true           # Push to remote repository.

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
  echo "        Mandatory (only if pushing to remote is active). GitHub owner of the repository."
  echo "        NOTE: Must have permissions to create the repository for this owner."
  echo "    -d, --activate-dependabot"
  echo "        Activate Dependabot dependency analysis."
  echo "    -p, --force-pr-contribution"
  echo "        For using PRs for code contributions, no code can be pushed to master branch."
  echo "    -r, --no-push-remote"
  echo "        Push created skeleton to remote repository."
  echo "        NOTE: It only creates the repository. If the repository is already created, no changes are staged."
  echo "        NOTE: Pushes to remote by defualt."
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
  # When no options, the user might just want to know how the command works,
  # thefore, equivalent to run --help.
  if [ "$#" -eq 0 ]
  then
    echo "[WARNING]: You are executing this command without options. Some of them are mandatory."
    echo
    help
  fi

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
        DEPENDABOT=true
      ;;
      --force-pr-contribution | -p)
        FORCE_PR=true
      ;;
      --no-push-remote | -r)
        PUSH=false
      ;;
      --file | -f)
          echo "Using a file for configuration is still on the making."
          echo "Run --help command to see how to configure the options manually."
          exit 0
      ;;
      --help | -h)
        help
      ;;
      *)
        echo "[ERROR]: $1 is not recognized as a valid argument. Run --help command to see valid arguments."
        exit 1
      ;;
    esac
    shift # Iterate to next parameter
  done

  # Check for mandatory fields
  [ -z "$REPO_NAME" ] && echo "[ERROR]: --name option is mandatory. See --help for more information."
  "$PUSH" && [ -z "$OWNER" ] && echo "[ERROR]: The skeleton is going to be pushed to a remote repository. Needs an --owner to continue."
  [ ! -z "$OWNER" ] && ! "$PUSH" && echo "[WARNING]: The repository skeleton won't be pushed to remote repository. --owner will be ignored."
}

function check_dependencies() {
  if [[ ! $(which git) ]]
  then
    echo "Git is a dependency for this script. Install it before continuing."
    exit 1
  fi
  # TODO: check technologies dependencies
}

function create_repo() {
    # Filter parameters
    get_parameters "$@"
    # See if all dependencies are installed
    check_dependencies
}

create_repo "$@"
