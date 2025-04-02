#!/bin/bash

set -e

# Function to fetch and sanitize branch names
get_branches() {
  local repo_path=$1
  git -C "$repo_path" fetch --all
  git -C "$repo_path" branch -r | sed 's/origin\///' | grep -v '\->' | while read -r branch; do
    # Sanitize branch name (replace / with -)
    echo "$branch" | sed 's#/#-#g'
  done | sort
}

# Function to fetch and sanitize current repository branches
get_current_branches() {
  git fetch --all
  git branch -r | sed 's/origin\///' | grep -v '\->' | sort
}

# Function to delete a branch
delete_branch() {
  local branch=$1
  echo "Deleting branch: $branch"
  git push origin --delete "$branch"
}

# Define an array of repositories to check
REPOSITORIES=(
  "serverRepo"
  "billingRelayRepo"
  # Add more repositories here as needed
)

# Get sanitized branch lists from all repositories
ALL_EXTERNAL_BRANCHES=""
for repo in "${REPOSITORIES[@]}"; do
  ALL_EXTERNAL_BRANCHES+=$(get_branches "$repo")
  ALL_EXTERNAL_BRANCHES+=$'\n' # Add a newline to separate branches from different repos
done

# Get sanitized branch list from the current repository
CURRENT_BRANCHES=$(get_current_branches)

# Find branches to delete
for branch in $CURRENT_BRANCHES; do
  if ! echo "$ALL_EXTERNAL_BRANCHES" | grep -q "^$branch$"; then
    delete_branch "$branch"
  fi
done