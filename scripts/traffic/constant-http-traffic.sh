#!/usr/bin/env bash

set -euEo pipefail

OPTS=("-n" "10000" "-c" "20")
if [ $# -gt 0 ]; then
  OPTS+=("$@")
fi

while true; do
  POD=$(kubectl get pods -n http-client -l app.kubernetes.io/name=http-client \
    -o jsonpath='{.items[0].metadata.name}' 2> /dev/null || true)

  SPACE=" "
  if ! kubectl exec "$POD" -n http-client -- ls hey > /dev/null 2>&1; then
    kubectl cp ~/workspace/hey_linux_amd64 -c http-client "http-client/$POD:hey" > /dev/null 2>&1 || true
    kubectl exec -n http-client -c http-client "$POD" -- chmod +x /hey > /dev/null 2>&1 || true
    sleep 5
    SPACE="^"
  fi

  echo "$(date)$SPACE$( (kubectl exec -n http-client "$POD" -c http-client -- \
      ./hey "${OPTS[@]}" http://http-server.http-server.svc.cluster.local:8000/get | grep responses) 2> /dev/null )"
done
