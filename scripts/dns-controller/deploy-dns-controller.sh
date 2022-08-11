#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [[ ${RELEASE_PATH:-} == "" ]]; then
  echo "RELEASE_PATH is undefined"
  exit 1
fi

CHART_DIR=$RELEASE_PATH/manifests/charts/dns-controller
if [ ! -d "$CHART_DIR" ]; then
  echo "Directory manifests/charts/dns-controller not found in RELEASE_PATH ($RELEASE_PATH)"
  exit 1
fi

if [[ ${OVERRIDES:-} == "" ]]; then
  OVERRIDES=${OVERRIDES:-"$DIR/overrides.yaml"}
  echo "Defaulting overrides to $OVERRIDES"
fi

helm upgrade --install dns-controller -n istio-system "$CHART_DIR" \
  --values="$OVERRIDES" \
  --set maxConcurrentReconciles=5 \
  --set dnsClientTimeout=10s

kubectl apply -f "$DIR/servicemonitor.yaml"
