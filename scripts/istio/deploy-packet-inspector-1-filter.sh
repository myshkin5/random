#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

export DEFAULT_OVERRIDES="$DIR/overrides/packet-inspector.yaml"
source "$DIR/version-support.sh"

FILTER_CHART="$RELEASE_PATH/manifests/charts/packet-inspector-1-filter"
if [ ! -d "$FILTER_CHART" ]; then
  >&2 echo "No Packet Inspector 1 filter chart found in release (should be here $FILTER_CHART)"
fi

for NS in "$@"; do
  helm upgrade packet-inspector-1-filter "$FILTER_CHART" \
    --install \
    --namespace=$NS "${VALUES_OPTS[@]}"
done
