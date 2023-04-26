#!/usr/bin/env bash

set -xeuEo pipefail

# Probably main or master
STARTING_BRANCH=$(git rev-parse --abbrev-ref HEAD)

git checkout --orphan fork
git rm -rf .
git commit --allow-empty -m fork
git push origin fork

# Back to upstream main (or master)
git checkout "$STARTING_BRANCH"

git branch -D fork

# Remove all origin tags
git ls-remote --tags --quiet --refs origin | while read -r _ tag; do git push origin ":$tag"; done

# Get the repo name and switch the default branch to fork
REPO=$(basename -s .git "$(git config --get remote.origin.url)")
gh api -XPATCH "repos/myshkin5/$REPO" -f default_branch=fork > /dev/null

# Delete main (or master). NOTE: ONLY ON ORIGIN!
git push origin --delete "$STARTING_BRANCH"
