#!/usr/bin/env bash
set -euo pipefail

# Call to GitHub API
function github_api() {
  curl -s -L -w "%{http_code}" \
       -X "$1" \
       -H "Accept: application/vnd.github.v3+json" \
       -u "$REPO_OWNER:${ACCESS_TOKEN}" \
       -d "$2" \
       "$3"
}

function repo_exists() {
  if [ "$#" -eq 3 ]
  then
    response=$(github_api GET "" "$1/$2/$3")
    status_code=$(echo "$response" | tail -c 4)
    [[ "$status_code" =~ ^20[0-9]$ ]]
  fi
}

function create_repo() {
  if [ "$#" -eq 3 ]
  then
    response=$(github_api POST "{\"name\":\"$1\", \"private\": $2}" "$3")
    status_code=$(echo "$response" | tail -c 4)
    [[ ! "$status_code" =~ ^20[0-9]$ ]]
  fi
}

# Check for a package being installed in the system.
function is_installed() {
  # Check parameters
  [ "$#" -ne 2 ] &&
    echo "[ERROR]: is_installed takes two arguments: is_installed <to-check> <err-msg>" &&
    return 1

  # Check if module is installed
  if [[ ! $(command -v $1) ]]
  then
    echo "[ERROR]: $1 $2"
    return 1
  else
    return 0
  fi
}

# Check is a variable is a boolean
function is_bool() {
  # Check parameters
  [ "$#" -ne 1 ] &&
    echo "[ERROR]: is_bool takes one argument: is_bool <to-check>" &&
    return 1

  # Check if variable is boolean
  case $1 in
    true | false)
      return 0
      ;;
    *)
      echo "[WARNING]: the given value is not a boolean..."
      return 1
      ;;
  esac
}

# Check if a variable has a valid interval value:
# - daily
# - weekly
# - monthly
function is_valid_interval() {
  # Check parameters
  [ "$#" -ne 1 ] &&
    echo "[ERROR]: valid_interval takes one argument: valid_interval <to-check>" &&
    exit 1

  # Check if variable has a valid value
  case $1 in
    daily | weekly | montly)
      return 0
      ;;
    *)
      echo "[WARNING]: $1 is not a valid interval: daily, weekly or monthly are..."
      return 1
      ;;
  esac
}
