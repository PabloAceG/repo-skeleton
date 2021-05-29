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
LICENSE_URL="https://raw.githubusercontent.com/licenses/license-templates/master/templates/"

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
  echo "        Mandatory. GitHub owner of the repository."
  echo "        NOTE: Must have permissions to create the repository for this owner."
  echo "    -l, --license <license-name>"
  echo "        Optional. Select license for the repository."
  echo "        NOTE: If no license selected, unlicense will be used."
  echo "        NOTE: Look at the following repository to choose the best option: "
  echo "        https://github.com/licenses/license-templates"
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

  # Use configuration file
  if [ ! -z "$FILE" ]
  then
    echo "[WARNING]: Using configuration file. The rest of the arguments will be ignored."
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

  # Check for mandatory fields
  [ -z "$REPO_NAME" ] && echo "[ERROR]: --name option is mandatory. See --help for more information."
  [ -z "$REPO_OWNER" ] && echo "[ERROR]: --owner argument is mandatory. See --help for more information."

  echo "[INFO]: Parameters read."
}

function check_dependencies() {
  echo "[INFO]: Checking dependecies..."

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

  echo "[INFO]: All dependencies are correct."
}

function init_files() {
    echo "Creating initial commit..."
    # Create README file
    echo "$REPO_NAME" > README.md
    # Create license
    if [ -z $LICENSE_NAME ]
    then
      echo "[WARNING]: No license specified, using unlicense."
      echo "[DISCLAIMER]: You should choose a LICENSE that suits the purpose of your project."
      echo "[DISCLAIMER]: You can see the available licenses in:"
      echo "https://github.com/licenses/license-templates"
      LICENSE_NAME=unlicense
    fi
    curl -L "${LICENSE_URL}${LICENSE_NAME}.txt" > LICENSE
    sed -i                                        \
        -e "s/{{ year }}/$(date +"%Y")/g"         \
        -e "s/{{ organization }}/${REPO_OWNER}/g" \
        -e "s/{{ project }}/${REPO_NAME}/g"       \
        LICENSE
}

function create_repo() {
  echo "[INFO]: Starting execution..."

  # Filter parameters
  get_parameters "$@"

  # See if all dependencies are installed
  check_dependencies

  # Create initial commit
  if [ -e "$REPO_NAME" ]
  then
    echo "[ERROR]: There is a already folder with your repository name. It won't be created."
    exit  1
  fi

  mkdir "$REPO_NAME"
  cd "$REPO_NAME"
  init_files
  git init
  git add README.md
  git commit -m "First commit"
}

create_repo "$@"
