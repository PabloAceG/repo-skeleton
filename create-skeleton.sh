#!/usr/bin/env bash
set -euo pipefail

source ./sources/utils.sh

#################################################################################
#Script Name    :create-skeleton.sh
#Description    :create the skeleton of scripts with different configuration
#                options
#Args           :See help for more information.
#Author         :Pablo Acereda
#Email          :p.aceredag@gmail.com
#################################################################################

# Command to execute
COMMAND=repo_skeleton

## Paths
PATH_SCRIPT=$(dirname $(realpath $0))
PATH_SOURCES="$PATH_SCRIPT/sources"
PATH_DEPENDABOT="$PATH_SOURCES/dependabot"
DEST_DEPENDABOT='.github'
PATH_HOOKS="$PATH_SOURCES/hooks"
DEST_HOOKS='.githooks'

## Defaults
FILE=""
# Repository
REPO_NAME=""
REPO_OWNER=""
LICENSE_NAME=""
PUSH=true           # Push to remote repository.
# Technologies
TECHNOLOGY=""
# Remote characteristics
ACCESS_TOKEN=""
PRIVATE=false       # Public remote repository.
DEPENDABOT=false    # Don't activate Dependabot.
DEPENDABOT_INTERVAL="daily"
FORCE_PR=false      # Don't for PRs for contributions.

## URLs
GH_GET_REPO_URL="https://api.github.com/repos"
GH_CREATE_REPO_URL="https://api.github.com/user/repos"
LICENSE_URL="https://raw.githubusercontent.com/licenses/license-templates/master/templates"

# Command help
function help() {
  echo "NAME"
  echo "    create-skeleton.sh"
  echo
  echo "SYNOPSIS"
  echo "    create-skeleton [options]"
  echo
  echo "DESCRIPTION"
  echo "    Script that facilitates the creation of repository skeleton. It pushes changes to a remote repository."
  echo
  echo "OPERATIONS"
  echo "    -f, --file <filename>"
  echo "        Use configuration file instead of parameters to configure behaviour of this script."
  echo
  echo "    -h, --help"
  echo "        Displays this manual."
  echo
  echo "PARAMETERS"
  echo "    Are not taken into account if -f/--file is passed."
  echo
  echo "    -n, --name <repository-name>"
  echo "        Name of the repository."
  echo
  echo "    -o, --owner <repository-owner>"
  echo "        GitHub owner of the repository."
  echo
  echo "    -t, --token <token>"
  echo "        Mandatory (unless -r/--no-push-remote). GitHub authentication token for specified user/organization."
  echo "        NOTE: Should have permissions to create a repository."
  echo
  echo "OPTIONS"
  echo "    Are not taken into account if -f/--file is passed."
  echo
  echo "    --dependabot"
  echo "        Activate Dependabot dependency analysis."
  echo
  echo "    --dependabot-interval <interval>"
  echo "        Select Dependabot check-for-update period. If nothing is chosen, daily is selected."
  echo
  echo "            Available intervals:"
  echo "              daily, weekly, monthly"
  echo
  echo "    --license <license-name>"
  echo "        Select license for the repository. If no license is selected unlicense is used."
  echo "        To learn more about supported licenses, take a look into: "
  echo "        https://github.com/licenses/license-templates"
  echo
  echo "    --no-push-remote"
  echo "        Do not push skeleton into remote repository."
  echo
  echo "    --pr-contribution"
  echo "        For using PRs for code contributions, no code can be pushed to master branch."
  echo
  echo "    --private"
  echo "        Private visibility of the repository. If not specified, repository is public."
  echo
  echo "    -technology <tech-name>"
  echo "        Main technology to base the repository in. Take a look into SUPPORTED TECHNOLOGIES section to learn more about available technologies."
  echo
  echo "SUPPORTED TECHNOLOGIES"
  echo "    - Rust"
  echo
  echo "EXAMPLES"
  echo "    create-skeleton.sh --help"
  echo "        To better know how this script works."
  echo
  echo "    create-skeleton.sh --name myRepoSkeleton --owner PabloAceG --token qwertyuiopasdfghjklzxcvbnm"
  echo "        Create a plain repository with no technologies called 'myRepoSkeleton' being the owner 'PabloAceG'."
  echo
  echo "SUPPORT THIS SCRIPT"
  echo "    If you wanto to expand the functionality of this script, you can colaborate opening an Issue with your suggestion or open a Pull request in"
  echo "    https://github.com/PabloAceG/repo-skeleton"
  echo
  echo "AUTHORS"
  echo "    - Pablo Acereda <p.aceredag@gmail.com>"
  echo
  echo "create-skeleton.sh v0.1         2021-05-30"
}

function correct_parameters() {
  # Mandatory
  if [ -z "$REPO_NAME" ]
  then
    echo "[ERROR]: --name option is mandatory. See --help for more information."
    return 1
  fi
  if [ -z "$REPO_OWNER" ]
  then
    echo "[ERROR]: --owner argument is mandatory. See --help for more information."
    return 1
  fi

  # Optional that can be set if nothing is passed
  if [ -z "$LICENSE_NAME" ]
  then
    echo "[WARNING]: No license specified, using unlicense."
    echo "[WARNING]: You should choose a LICENSE that suits the purpose of your project."
    echo "[WARNING]: You can see the available licenses in:"
    echo "https://github.com/licenses/license-templates"
    LICENSE_NAME=unlicense
  fi
  if [ $(is_bool $PUSH) ]
  then
    PUSH=false
    echo "[WARNING]: Not pushing to remote repository, as none was specified..."
  fi

  # Dependant from other variable
  if $PUSH
  then
    if [ -z "$ACCESS_TOKEN" ]
    then
      echo "[ERROR]: when pushing to remote --token argument is mandatory. See --help for more information."
      return 1
    fi
    if [[ $(is_bool "$PRIVATE") -eq 1 ]]
    then
      PRIVATE=true
      echo "[WARNING]: Making repository private, as none was specified..."
    fi
    if [[ $(is_bool "$DEPENDABOT") -eq 1 ]]
    then
      DEPENDABOT=false
      echo "[WARNING]: Not activating Dependabot, as nothing was specified..."
    fi
    if $DEPENDABOT && [[ $(is_valid_interval "$DEPENDABOT_INTERVAL") -eq 1 ]]
    then
      DEPENDABOT_INTERVAL="daily"
      echo "[WARNING]: Dependabot daily check-for-updates has been set, as none was specified..."
    fi
    if [[ $(is_bool "$FORCE_PR") -eq 1 ]]
    then
      FORCE_PR=false
      echo "[WARNING]: Not rorcing PR for contributions, as none was specified..."
    fi
  fi
}

# Obtain script parameters from command line arguments.
function get_parameters() {
  # When no options, the user might just want to know how the command works,
  # thefore, equivalent to run --help.
  if [ "$#" -eq 0 ]
  then
    echo "[WARNING]: You are executing this command without options. Some of them are mandatory..."
    help
    return 1
  fi

  while [ "$#" -gt 0 ]
  do
    case "$1" in
      --file | -f)
        shift
        FILE="$1"
        break
        ;;
      --help | -h)
        COMMAND=help
        return 0
        ;;
      --name | -n)
        shift
        REPO_NAME="$1"
        ;;
      --owner | -o)
        shift
        REPO_OWNER="$1"
        ;;
      --token | -t)
        shift
        ACCESS_TOKEN="$1"
        ;;
      --dependabot)
        DEPENDABOT=true
        ;;
      --dependabot-interval)
        shift
        DEPENDABOT_INTERVAL="$1"
        ;;
      --license)
        shift
        LICENSE_NAME="$1"
        ;;
      --no-push-remote)
        PUSH=false
        ;;
      --pr-contribution)
        FORCE_PR=true
        ;;
      --private)
        PRIVATE=true
        ;;
      --technology)
        shift
        TECHNOLOGY="$1"
        ;;
      *)
        echo "[ERROR]: $1 is not recognized as a valid argument. Run --help command to see valid arguments."
        return 1
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
      return 1
    fi
    # Get parameters from configuration file
    source "$FILE"
    # Assign parameters
    REPO_NAME="$REPO"
    REPO_OWNER="$OWNER"
    ACCESS_TOKEN="$TOKEN"
    LICENSE_NAME="$LICENSE"
    TECHNOLOGY="$MAIN_TECH"
    DEPENDABOT="$DEPENDENCIES"
    DEPENDABOT_INTERVAL="$DEPENDENCIES_INTERVAL"
    FORCE_PR="$PR"
    PUSH="$REMOTE"
    PRIVATE="$MAKE_PRIVATE"
  fi

  # Check for parameters being configured as needed
  correct_parameters
}

# Download license
function get_license() {
  curl -s                                  \
       -L "$LICENSE_URL/$LICENSE_NAME.txt" \
       -o LICENSE
  sed -i                                        \
      -e "s/{{ year }}/$(date +"%Y")/g"         \
      -e "s/{{ organization }}/${REPO_OWNER}/g" \
      -e "s/{{ project }}/${REPO_NAME}/g"       \
      LICENSE
}

# Check dependencies necessary to execute the script.
function check_dependencies() {
  echo "[INFO]: Checking dependecies..."

  error_msg1="is a dependency for this script. Please install it before continuing."
  error_msg2="is necessary to build the skeleton of the repository. Please install it before continuing."

  is_installed "git" "$error_msg1"
  is_installed "curl" "$error_msg1"

  case "${TECHNOLOGY,,}" in
    rust)
      is_installed "rustc" "$error_msg2"
      is_installed "cargo" "$error_msg2"
    ;;
    *)
      echo "[ERROR]: $TECHNOLOGY is not currently supported. See --help command to learn about supported technologies."
      return 1
    ;;
  esac

  echo "[INFO]: Checking dependecies... Done"
}

# Delete local repository.
function rollback_local_repo() {
      echo "[ERROR]: $1"
      echo "[ERROR]: Deleting local repository."
      echo "[WARNING]: You might want to activate -r/--no-push-remote flag to preserve changes."
      cd ..
      rm -Rf "$REPO_NAME"
      return 1
}

function block_push_master() {
  if "$FORCE_PR"
  then
    echo "[INFO]:   Blocking push to master branch..."
    # Create hook
    mkdir "$DEST_HOOKS"
    cp "$PATH_HOOKS/pre-push" "$DEST_HOOKS"
    # Add changes to git
    git add "$DEST_HOOKS/pre-push" 1>/dev/null
    git commit --quiet -m 'Avoid pushing changes to master branch'
    git config --local core.hooksPath "$DEST_HOOKS" 1>/dev/null
    echo "[INFO]:   Blocking push to master branch... Done"
  fi
}

function activate_dependabot() {
  if "$DEPENDABOT"
  then
    echo "[INFO]:   Activating dependency control with Dependabot..."
    # Create folder
    mkdir "$DEST_DEPENDABOT"

    # Create file
    cp "$PATH_DEPENDABOT/dependabot.yml.sample" "$DEST_DEPENDABOT/dependabot.yml"
    # Add technology specify dependency control to Dependabot configuration file
    case ${TECHNOLOGY,,} in
      rust)
        echo "[INFO]:     Adding Cargo (Rust) to Dependabot for dependency control..."
        cat "$PATH_DEPENDABOT/dependabot-rust.yml.sample" >> "$DEST_DEPENDABOT/dependabot.yml"
        echo "[INFO]:     Adding Cargo (Rust) to Dependabot for dependency control... Done"
      ;;
    esac
    sed -i -e "s/{{ interval }}/\"${DEPENDABOT_INTERVAL}\"/g" "$DEST_DEPENDABOT/dependabot.yml"
    # Add changes to git
    git add "$DEST_DEPENDABOT" 1>/dev/null
    git commit --quiet -m 'Add dependency control using Dependabot'

    echo "[INFO]:   Activating dependency control with Dependabot... Done"
  fi
}

function project_skeleton() {
  case ${TECHNOLOGY,,} in
    rust)
      echo '[INFO]:   Creating Rust Skeleton...'
      cargo init -q
      echo "[INFO]:     Change project information in Cargo.toml file..."
      # Adding changes
      git add . 1>/dev/null
      git commit --quiet -m 'Rust skeleton'
      echo '[INFO]:   Creating Rust Skeleton... Done'
    ;;
  esac
}

# Create local repository with selected LICENSE and README files. It also creates an skeleton for the chosen
# technologies.
function create_local_repository() {
  # No folder in current directory has the same name
  echo "[INFO]: Creating local repository..."
  if [ -e "$REPO_NAME" ]
  then
    echo "[ERROR]: There is a already folder with your repository name. It won't be created."
    return  1
  fi

  # Create folder
  mkdir "$REPO_NAME"
  cd "$REPO_NAME"

  # Create README
  echo "* $REPO_NAME" > README.org
  # Create LICENSE
  get_license

  # Initialize local repository
  git init --quiet
  git add README.org LICENSE 1>/dev/null
  git commit --quiet -m 'First commit'

  # Define skeleton for specific language/project
  project_skeleton
  # Activate Dependabot for dependency update
  activate_dependabot
  # Force PRs to contribute to project
  # BUG: Must learn how to create PR from terminal or API
  block_push_master

  echo "[INFO]: Creating local repository... Done"
}

# Create remote repository in GitHub and push local content.
function create_remote_repository() {
  if "$PUSH"
  then
    echo "[INFO]: Creating remote repository..."
    # Repo does not exists in remoet
    echo "[INFO]:   Checking if remote repository already exists..."
    response=$(github_api GET "" "$GH_GET_REPO_URL/${REPO_OWNER}/${REPO_NAME}")
    status_code=$(echo "$response" | tail -c 4)
    [[ "$status_code" =~ ^20[0-9]$ ]] && rollback_local_repo "The repository already exists..."
    echo "[INFO]:   Checking if remote repository already exists... Done"

    # Create remote repository
    echo "[INFO]:   Creating repository in remote server..."
    response=$(github_api POST "{\"name\":\"${REPO_NAME}\", \"private\": ${PRIVATE}}" "$GH_CREATE_REPO_URL")
    status_code=$(echo "$response" | tail -c 4)
    [[ ! "$status_code" =~ ^20[0-9]$ ]] && rollback_local_repo "The repository couldn't be created..."
    echo "[INFO]:   Creating repository in remote server... Done"

    # Push content
    echo "[INFO]:   Pushing initial content into repository..."
    git remote add origin "https://github.com/${REPO_OWNER}/${REPO_NAME}" 1>/dev/null
    git push --quiet --set-upstream origin master
    echo "[INFO]:   Pushing initial content into repository... Done"
  fi
}

# Main functiona. Creates a repository skeleton taking certain parameters and configuration options.
function repo_skeleton() {
  echo "[INFO]: Creating repository skeleton..."
  # See if all dependencies are installed
  check_dependencies || return $?

  create_local_repository || return $?
  create_remote_repository || return $?

  echo "[INFO]: Creating repository skeleton... Done"
}

function run_repo_skeleton() {
  # Filter parameters
  get_parameters "$@" || return $?

  $COMMAND
}

run_repo_skeleton "$@"
