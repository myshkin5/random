#!/usr/bin/env bash

set -xeuEo pipefail

git checkout --orphan fork
git rm -rf .
git commit --allow-empty -m fork
git push origin fork
git checkout main
git branch -D fork
git ls-remote --tags --quiet --refs origin | while read -r _ tag; do git push origin ":$tag"; done
