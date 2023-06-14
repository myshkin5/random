#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"

if [[ ${RELEASE_PATH:-} == "" ]]; then
  echo "RELEASE_PATH is undefined"
  exit 1
fi

CHART_DIR=$RELEASE_PATH/manifests/charts/dns-controller
if [ ! -d "$CHART_DIR" ]; then
  echo "Directory manifests/charts/dns-controller not found in RELEASE_PATH ($RELEASE_PATH)"
  exit 1
fi

helm-upgrade dns-controller "$CHART_DIR" \
  "${DNS_CONTROLLER_VALUES:-"$DIR/config.yaml"}" \
  --namespace istio-system

kubectl apply -f "$DIR/servicemonitor.yaml"
