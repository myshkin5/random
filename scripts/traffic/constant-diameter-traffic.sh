#!/usr/bin/env bash

set -euEo pipefail

OPTS=("-bench" "-bench_clients" "1" "-bench_msgs" "1000" "-bench_timeout" "1s")
if [ $# -gt 0 ]; then
  OPTS+=("$@")
fi

while true; do
  POD=$(kubectl get pods -n diameter-client \
    -l app=diameter-client \
    -o jsonpath='{.items[0].metadata.name}' 2> /dev/null || true)

  RET_CODE=0
  kubectl exec -n diameter-client "$POD" -c diameter-client -- \
    diameter-client -addr diameter-server.diameter-server:3868 "${OPTS[@]}" 2>&1 | grep "messages in" || RET_CODE=$?
  if [ "$RET_CODE" != 0 ]; then
    date
    sleep 5
  fi
done
