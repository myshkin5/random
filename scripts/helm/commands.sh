#!/usr/bin/env bash

set -euEo pipefail

helm-upgrade() {
  local RELEASE=$1
  local CHART=$2
  local VALUES=$3
  shift 3
  local OPTS=("$@")
  if [ -n "$VALUES" ]; then
    IFS=':' read -ra VS <<< "$VALUES"
    for V in "${VS[@]}"; do
      if [[ -z "$V" ]]; then
        continue
      fi
      if [ -f "$V" ]; then
        OPTS+=("--values=$V")
      else
        OPTS+=("$V")
      fi
    done
  fi

  helm upgrade "$RELEASE" "$CHART" --install "${OPTS[@]}"
}
