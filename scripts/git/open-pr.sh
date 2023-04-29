#!/usr/bin/env bash

set -euEo pipefail

git push

GH_UPSTREAM=${GH_UPSTREAM:-upstream}

git config --local --get "remote.$GH_UPSTREAM.gh-resolved" > /dev/null || {
  gh repo set-default
}

OPTS=("--web" "--repo" "$(git remote get-url "$GH_UPSTREAM")")
for LABEL in ${GH_DEFAULT_LABELS:-}; do
  OPTS+=("--label" "$LABEL")
done

gh pr create "${OPTS[@]}" "$@"
