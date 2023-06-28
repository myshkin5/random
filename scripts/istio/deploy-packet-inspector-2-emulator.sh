#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"
source "$DIR/version-support.sh"

ANALYSIS_CHART="$RELEASE_PATH/samples/aspenmesh/packet-inspector-2-analysis-emulator"
if [ ! -d "$ANALYSIS_CHART" ]; then
  >&2 echo "No Analysis Emulator chart found in release (should be here $RELEASE_PATH/samples/aspenmesh/packet-inspector-2-analysis-emulator)"
  exit 1
fi

kubectl apply -f "$DIR/analysis-emulator-2-ns.yaml"
helm-upgrade analysis-emulator "$ANALYSIS_CHART" \
  "${PI_2_EMULATOR_VALUES:-"$DIR/config/packet-inspector/analysis-emulator-2.yaml"}" \
  --namespace=analysis-emulator-2

kubectl wait pods -n analysis-emulator-2 \
  -l app.kubernetes.io/name=packet-inspector-2-analysis-emulator \
  --for condition=Ready --timeout=5m

kubectl apply -f "$DIR/analysis-emulator-2-servicemonitor.yaml"
