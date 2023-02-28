#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

export DEFAULT_OVERRIDES="$DIR/overrides/packet-inspector.yaml"
source "$DIR/version-support.sh"

ANALYSIS_CHART="$RELEASE_PATH/samples/aspenmesh/packet-inspector-1-analysis-emulator"
if [ ! -d "$ANALYSIS_CHART" ]; then
  ANALYSIS_CHART="$RELEASE_PATH/samples/aspenmesh/analysis-emulator"
fi
if [ ! -d "$ANALYSIS_CHART" ]; then
  >&2 echo "No Analysis Emulator chart found in release (should be here $RELEASE_PATH/samples/aspenmesh/*analysis-emulator)"
  exit 1
fi

PACKET_INSPECTOR_CHART="$RELEASE_PATH/manifests/charts/packet-inspector"
if [[ ! -d "$PACKET_INSPECTOR_CHART" && "$ISTIO_MINOR_VERSION" != "1.11" ]]; then
  >&2 echo "No Packet Inspector chart found in release (should be here $PACKET_INSPECTOR_CHART)"
  exit 1
fi

kubectl apply -f "$DIR/analysis-emulator-ns.yaml"
helm upgrade analysis-emulator "$ANALYSIS_CHART" \
  --install \
  --namespace=analysis-emulator "${VALUES_OPTS[@]}" "$@"

if [[ -d "$PACKET_INSPECTOR_CHART" ]]; then
  # Already deployed in 1.11 releases
  helm upgrade packet-inspector "$PACKET_INSPECTOR_CHART" \
    --install \
    --namespace=istio-system "${VALUES_OPTS[@]}" "$@"
fi

kubectl apply -f "$DIR/packet-inspector-1-servicemonitor.yaml"
kubectl apply -f "$DIR/analysis-emulator-servicemonitor.yaml"
