#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"
source "$DIR/version-support.sh"

RESP_ORIG_CHART="$RELEASE_PATH/manifests/charts/response-origin"
if [ ! -d "$RESP_ORIG_CHART" ]; then
  >&2 echo "No response origin chart found in release (should be here $RESP_ORIG_CHART)"
  exit 1
fi

helm-upgrade response-origin "$RESP_ORIG_CHART" \
  --namespace=istio-system
