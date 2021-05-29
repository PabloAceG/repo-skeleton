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
REPO_OWNER=""
LICENSE_NAME=""
TECHNOLOGIES=[]
DEPENDABOT=false    # Don't activate Dependabot.
FORCE_PR=false      # Don't for PRs for contributions.
PUSH=true           # Push to remote repository.
FILE=""

# Urls
LICENSE_URL="https://github.com/licenses/license-templates/tree/master/templates/"

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
  echo "    -l, --license <license-name>"
  echo "        Optional. Select license for the repository."
  echo "        NOTE: Look at the following repository to choose the best option: "
  echo "        $LICENSE_URL"
  echo "    -d, --activate-dependabot"
  echo "        Optional. Activate Dependabot dependency analysis."
  echo "    -p, --force-pr-contribution"
  echo "        Optional. For using PRs for code contributions, no code can be pushed to master branch."
  echo "    -r, --no-push-remote"
  echo "        Optional. Push created skeleton to remote repository."
  echo "        NOTE: It only creates the repository. If the repository is already created, no changes are staged."
  echo "        NOTE: Pushes to remote by defualt."
  echo "    -f, --file"
  echo "        Optional. File configuration of this script."
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
        REPO_OWNER=$1
      ;;
      --license | -l)
        shift
        LICENSE_NAME=$1
      ;;
      --techs | -t)
        echo "On the making"
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
          shift
          FILE=$1
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
  if [ -z "$FILE" ]
  then
    [ -z "$REPO_NAME" ] && echo "[ERROR]: --name option is mandatory. See --help for more information."
    "$PUSH" && [ -z "$REPO_OWNER" ] && echo "[ERROR]: The skeleton is going to be pushed to a remote repository. Needs an --owner to continue."
    [ ! -z "$REPO_OWNER" ] && ! "$PUSH" && echo "[WARNING]: The repository skeleton won't be pushed to remote repository. --owner will be ignored."
  else
      [ ! -z "$REPO_NAME" ] && echo "[WARNING]: Used configuration file instead. --name/-n will be ignored."
      [ ! -z "$REPO_OWNER" ] && echo "[WARNING]: Used configuration file instead. --owner/-o will be ignored."
      [ ! -z "$LICENSE_NAME" ] && echo "[WARNING]: Used configuration file instead. --license/-l will be ignored."
      [ ! -z "$TECHNOLOGIES" ] && echo "[WARNING]: Used configuration file instead. --techs/-t will be ignored."
      [ ! -z "$DEPENDABOT" ] && echo "[WARNING]: Used configuration file instead. --activate-dependabot/-d will be ignored."
      [ ! -z "$FORCE_PR" ] && echo "[WARNING]: Used configuration file instead. --force-pr-contribution/-p will be ignored."
      [ ! -z "$PUSH" ] && echo "[WARNING]: Used configuration file instead. --no-push-remote/-r will be ignored."
      # Check for file existance
      if [ ! -e "$FILE" ]
      then
        echo "[ERROR]: The specified configuration file does not exist. Check if the path is correct."
        exit 1
      fi
      # Get parameters from configuration file
      source "$FILE"
      REPO_NAME="$REPO"
      REPO_OWNER="$OWNER"
      LICENSE_NAME="$LICENSE"
      TECHNOLOGIES="$TECHS"
      FORCE_PR="$PR"
      PUSH="$REMOTE"
  fi
}

function check_dependencies() {
  if [[ ! $(which git) ]]
  then
    echo "[ERROR]: git is a dependency for this script. Install it before continuing."
    exit 1
  fi

  if [[ ! $(which curl) ]]
  then
    echo "[ERROR]: curl is a dependency for this script. Install it before continuing."
  fi

  # TODO: check technologies dependencies
}

function create_repo() {
    # Filter parameters
    get_parameters "$@"
    # See if all dependencies are installed
    check_dependencies

    # BUG: Repo might exist
    # Create initial commit
    #mkdir "$REPO_NAME"
    #cd "$REPO_NAME"
    #echo "$REPO_NAME" > README.md
    #git init
    #git add README.md
    #git commit -m "First commit"
}

create_repo "$@"
