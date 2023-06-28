#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"
source "$DIR/version-support.sh"

FILTER_CHART="$RELEASE_PATH/manifests/charts/packet-inspector-2-filter"
if [ ! -d "$FILTER_CHART" ]; then
  >&2 echo "No Packet Inspector 1 filter chart found in release (should be here $FILTER_CHART)"
  exit 1
fi

for NS in "$@"; do
  helm-upgrade packet-inspector-2-filter "$FILTER_CHART" \
    "${PI_2_FILTER_VALUES:-}" --namespace=$NS
done
