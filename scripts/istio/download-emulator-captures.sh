#!/bin/bash

set -xeuEo pipefail

if [[ $# != 1 ]]; then
  >&2 echo "Local directory not specified ($0 <dir>)"
  exit 1
fi

# TODO: Make work with multiple replicas
POD=""
while [ "$POD" == "" ]; do
  POD=$(kubectl get pod -n analysis-emulator \
    -l "app in (packet-inspector-1-analysis-emulator, analysis-emulator)" \
    -o jsonpath='{.items[0].metadata.name}' || true)
  sleep 1
done

kubectl cp -n analysis-emulator "$POD":tmp "$1"
