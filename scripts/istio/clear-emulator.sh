#!/bin/bash

set -xeuEo pipefail

# TODO: Make work with multiple replicas
POD=""
while [ "$POD" == "" ]; do
  POD=$(kubectl get pod -n analysis-emulator \
    -l app=analysis-emulator \
    -o jsonpath='{.items[0].metadata.name}' || true)
  sleep 1
done

kubectl exec -n analysis-emulator "$POD" \
  -- find /tmp -type f -print -exec rm {} \;
