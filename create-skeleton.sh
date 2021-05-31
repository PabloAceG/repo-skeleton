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
ACCESS_TOKEN=""
LICENSE_NAME=""
TECHNOLOGIES=[]
DEPENDABOT=false    # Don't activate Dependabot.
FORCE_PR=false      # Don't for PRs for contributions.
PUSH=true           # Push to remote repository.
PRIVATE=false       # Public remote repository.
FILE=""

# URLs
GH_GET_REPO_URL="https://api.github.com/repos"
GH_CREATE_REPO_URL="https://api.github.com/user/repos"
LICENSE_URL="https://raw.githubusercontent.com/licenses/license-templates/master/templates/"

# Command help
function help() {
  echo "NAME"
  echo "    create-skeleton.sh"
  echo
  echo "SYNOPSIS"
  echo "    create-skeleton [options]"
  echo
  echo "DESCRIPTION"
  echo "    Script that facilitates creating a repository skeleton."
  echo
  echo "OPTIONS"
  echo "    -n, --name <repository-name>"
  echo "        Mandatory. Name of the repository."
  echo
  echo "    -o, --owner <repository-owner>"
  echo "        Mandatory. GitHub owner of the repository."
  echo "        NOTE: Must have permissions to create the repository for this owner."
  echo
  echo "    -t, --token <token>"
  echo "        Mandatory (unless -r/--no-push-remote). GitHub authentication token for specified user/organization."
  echo "        NOTE: Should have permissions to create a repository."
  echo
  echo "    -l, --license <license-name>"
  echo "        Optional. Select license for the repository."
  echo "        NOTE: If no license selected, unlicense will be used."
  echo "        NOTE: Look at the following repository to choose the best option: "
  echo "        https://github.com/licenses/license-templates"
  echo
  echo "    -d, --activate-dependabot"
  echo "        Optional. Activate Dependabot dependency analysis."
  echo
  echo "    -p, --force-pr-contribution"
  echo "        Optional. For using PRs for code contributions, no code can be pushed to master branch."
  echo
  echo "    -r, --no-push-remote"
  echo "        Optional. Push created skeleton to remote repository."
  echo "        NOTE: It only creates the repository. If the repository is already created, no changes are staged."
  echo "        NOTE: Pushes to remote by defualt."
  echo
  echo "    -v, --private"
  echo "        Optional. Private visibility of the repository. If not specified, repository is public."
  echo "        NOTE: Only necessary when repository is created remotely (default unless -r/--no-push-remote)."
  echo
  echo "    -f, --file"
  echo "        Optional. File configuration of this script."
  echo
  echo "SUPPORTED TECHNOLOGIES"
  echo "    So far, the following technologies are supported: "
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
  exit 0
}

# Call to GitHub API
function github_api() {
  curl -s -L -w "%{http_code}" \
       -X "$1" \
       -H "Accept: application/vnd.github.v3+json" \
       -u "$REPO_OWNER:${ACCESS_TOKEN}" \
       -d "$2" \
       "$3"
}

function get_license() {
  curl -L "${LICENSE_URL}${LICENSE_NAME}.txt" > LICENSE
  sed -i                                        \
      -e "s/{{ year }}/$(date +"%Y")/g"         \
      -e "s/{{ organization }}/${REPO_OWNER}/g" \
      -e "s/{{ project }}/${REPO_NAME}/g"       \
      LICENSE
}

# Check for a package being installed in the system.
function is_installed() {
  if [[ ! $(command -v $1) ]]
  then
    echo "[ERROR]: $1 $2"
    exit 1
  fi
}

# Obtain script parameters from command line arguments.
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
      --token | -t)
        shift
        ACCESS_TOKEN=$1
      ;;
      --license | -l)
        shift
        LICENSE_NAME=$1
      ;;
      --techs | -x)
        shift
        read -a TECHNOLOGIES <<< "$1"
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
      --private | -v)
        PRIVATE=true
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
    ACCESS_TOKEN="$TOKEN"
    LICENSE_NAME="$LICENSE"
    read -a TECHNOLOGIES <<< "$TECHS" # Transform from str to arr
    FORCE_PR="$PR"
    PUSH="$REMOTE"
    PRIVATE="$PRIVATE"
  fi

  # Check for mandatory fields
  [ -z "$REPO_NAME" ] && echo "[ERROR]: --name option is mandatory. See --help for more information."
  [ -z "$REPO_OWNER" ] && echo "[ERROR]: --owner argument is mandatory. See --help for more information."
  [ -z "$ACCESS_TOKEN" ] && "$PUSH" && echo "[ERROR]: --token argument is mandatory. See --help for more information."

  echo "[INFO]: Parameters read."
}

# Check dependencies necessary to execute the script.
function check_dependencies() {
  echo "[INFO]: Checking dependecies..."

  error_msg1="is a dependency for this script. Please install it before continuing."
  error_msg2="is necessary to build the skeleton of the repository. Please install it before continuing."

  is_installed "git" "$error_msg1"
  is_installed "curl" "$error_msg1"

  for tech in "${TECHNOLOGIES[@]}"
  do
    case "${tech,,}" in
      rust)
        is_installed "rustc" "$error_msg2"
        is_installed "cargo" "$error_msg2"
      ;;
      *)
        echo "[ERROR]: $tech is not currently supported. See --help command to learn about supported technologies."
        exit 1
      ;;
    esac
  done

  echo "[INFO]: All dependencies are correct."
}

# Delete local repository.
function rollback_local_repo() {
      echo "[ERROR]: $1 No repository will be created."
      echo "[ERROR]: Deleting local repository."
      echo "[WARNING]: You might want to activate -r/--no-push-remote flag to preserve changes."
      cd ..
      rm -Rf "$REPO_NAME"
      exit 1
}

function project_skeleton() {
  # BUG: If more than one technology is used, skeletons might have conflicts among them
  for tech in "${TECHNOLOGIES[@]}"
  do
    case ${tech,,} in
      rust)
        cargo init -q
        echo "[INFO]: Rust skeleton has been created."
        # TODO: Provide configuration options using --config
        echo "[WARNING]: You should take a look at the Cargo.toml file to see that the information in it is correct."
        git add .
        git commit -m "Rust skeleton"
      ;;
      *)
        echo "[WARNING]: $tech is unsupported at this moment, but it is quite probably on the making. Be patient."
      ;;
    esac
  done
}

# Create local repository with selected LICENSE and README files. It also creates an skeleton for the chosen
# technologies.
function create_local_repository() {
  # No folder in current directory has the same name
  echo "[INFO]: Creating local repository..."
  if [ -e "$REPO_NAME" ]
  then
    echo "[ERROR]: There is a already folder with your repository name. It won't be created."
    exit  1
  fi

  # Create folder
  mkdir "$REPO_NAME"
  cd "$REPO_NAME"

  # Create README
  echo "* $REPO_NAME" > README.org

  # Create LICENSE
  if [ -z $LICENSE_NAME ]
  then
    echo "[WARNING]: No license specified, using unlicense."
    echo "[DISCLAIMER]: You should choose a LICENSE that suits the purpose of your project."
    echo "[DISCLAIMER]: You can see the available licenses in:"
    echo "https://github.com/licenses/license-templates"
    LICENSE_NAME=unlicense
  fi
  get_license

  # Initialize local repository
  git init
  git add README.org LICENSE
  git commit -m "First commit"

  # Define skeleton for specific language/project
  project_skeleton
  echo "[INFO]: Local repository has been created..."
}

# Create remote repository in GitHub and push local content.
function create_remote_repository() {
  if $PUSH
  then
    echo "[INFO]: Checking if remote repository already exists..."
    response=$(github_api GET "" "$GH_GET_REPO_URL/${REPO_OWNER}/${REPO_NAME}")
    status_code=$(echo "$response" | tail -c 4)
    [[ "$status_code" =~ ^20[0-9]$ ]] && rollback_local_repo "The repository already exists."

    echo "[INFO]: Creating remote repository..."
    response=$(github_api POST "{\"name\":\"${REPO_NAME}\", \"private\": ${PRIVATE}}" "$GH_CREATE_REPO_URL")
    status_code=$(echo "$response" | tail -c 4)
    [[ ! "$status_code" =~ ^20[0-9]$ ]] && rollback_local_repo "The repository couldn't be created."

    echo -e "[INFO]: Remote repository created. Pushing initial content into repository..."
    git remote add origin "https://github.com/${REPO_OWNER}/${REPO_NAME}"
    git push --set-upstream origin master
  fi
}

# Main functiona. Creates a repository skeleton taking certain parameters and configuration options.
function run_repo_skeleton() {
  echo "[INFO]: Starting execution..."
  # Filter parameters
  get_parameters "$@"
  # See if all dependencies are installed
  check_dependencies

  create_local_repository
  create_remote_repository
}

run_repo_skeleton "$@"
