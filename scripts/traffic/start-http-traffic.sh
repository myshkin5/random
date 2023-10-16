#!/bin/bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"

if (( $(kubectl get namespace | grep -c http-server) == 0 )); then
  kubectl create namespace http-server
fi
if [ "$AMBIENT" == true ]; then
  kubectl label namespace http-server istio.io/dataplane-mode=ambient
  kubectl label namespace http-server istio-injection-
else
  kubectl label namespace http-server istio-injection=enabled
  kubectl label namespace http-server istio.io/dataplane-mode-
fi

if (( $(kubectl get namespace | grep -c http-client) == 0 )); then
  kubectl create namespace http-client
fi
if [ "$AMBIENT" == true ]; then
  kubectl label namespace http-client istio.io/dataplane-mode=ambient
  kubectl label namespace http-client istio-injection-
else
  kubectl label namespace http-client istio-injection=enabled
  kubectl label namespace http-client istio.io/dataplane-mode-
fi

if (( $(kubectl get namespace | grep -c openshift) > 0 )); then
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace http-server
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace http-client
fi
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace http-server
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace http-client

helm-upgrade http-server "$DIR/../../charts/http-server" \
  "${HTTP_SERVER_VALUES:-}" --namespace http-server
helm-upgrade http-client "$DIR/../../charts/http-client" \
  "${HTTP_CLIENT_VALUES:-}" --namespace http-client

FAILED=0
while true; do
  while read -r POD; do
    RET_CODE=0
    (kubectl exec -n http-client -c http-client "$POD" \
      -- wget -O /dev/null http://http-server.http-server.svc.cluster.local:8000/get) || RET_CODE=$?
    if [ "$RET_CODE" != 0 ]; then
      FAILED=1
      break
    fi
  done < <(kubectl get pods -n http-client -l app.kubernetes.io/name=http-client -o json | \
    jq -r '.items[].metadata.name')

  if [ "$FAILED" == 1 ]; then
    FAILED=0
    continue
  fi
  break

  sleep 5
done
