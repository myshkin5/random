#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"
source "$DIR/version-support.sh"

CITADEL_CHART="$RELEASE_PATH/manifests/charts/security"
if [ ! -d "$CITADEL_CHART" ]; then
  >&2 echo "No Citadel chart found in release (should be here $CITADEL_CHART)"
  exit 1
fi

helm-upgrade citadel "$CITADEL_CHART" "${CITADEL_VALUES:-}" \
  --namespace=istio-system
