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

# Check for a package being installed in the system.
function is_installed() {
  if [[ ! $(command -v $1) ]]
  then
    echo "[ERROR]: $1 $2"
    exit 1
  fi
}
