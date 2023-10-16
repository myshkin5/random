#!/bin/bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"

if [ -z "$RELEASE_PATH" ]; then
  >&2 echo "RELEASE_PATH must be defined"
  exit 1
fi

DIAM_CLIENT_CHART="$RELEASE_PATH/samples/aspenmesh/diameter-client"
if [[ ! -d "$DIAM_CLIENT_CHART" ]]; then
  >&2 echo "No Diameter client chart found in release (should be here $DIAM_CLIENT_CHART)"
  exit 1
fi

DIAM_SERVER_CHART="$RELEASE_PATH/samples/aspenmesh/diameter-server"
if [[ ! -d "$DIAM_SERVER_CHART" ]]; then
  >&2 echo "No Diameter server chart found in release (should be here $DIAM_SERVER_CHART)"
  exit 1
fi

if (( $(kubectl get namespace | grep -c diameter-server) == 0 )); then
  kubectl create namespace diameter-server
fi
if [ "$AMBIENT" == true ]; then
  kubectl label namespace diameter-server istio.io/dataplane-mode=ambient
  kubectl label namespace diameter-server istio-injection-
else
  kubectl label namespace diameter-server istio-injection=enabled
  kubectl label namespace diameter-server istio.io/dataplane-mode-
fi

if (( $(kubectl get namespace | grep -c diameter-client) == 0 )); then
  kubectl create namespace diameter-client
fi
if [ "$AMBIENT" == true ]; then
  kubectl label namespace diameter-client istio.io/dataplane-mode=ambient
  kubectl label namespace diameter-client istio-injection-
else
  kubectl label namespace diameter-client istio-injection=enabled
  kubectl label namespace diameter-client istio.io/dataplane-mode-
fi

if (( $(kubectl get namespace | grep -c openshift) > 0 )); then
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace diameter-client
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace diameter-server
fi
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace diameter-client
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace diameter-server

helm-upgrade diameter-client "$DIAM_CLIENT_CHART" \
  "${DIAM_CLIENT_VALUES:-}" --namespace diameter-client
helm-upgrade diameter-server "$DIAM_SERVER_CHART" \
  "${DIAM_SERVER_VALUES:-}" --namespace diameter-server

FAILED=0
while true; do
  while read -r POD; do
    RET_CODE=0
    kubectl exec -n diameter-client -c diameter-client "$POD" \
      -- diameter-client -addr diameter-server.diameter-server:3868 -hello || RET_CODE=$?
    if [ "$RET_CODE" != 0 ]; then
      FAILED=1
      break
    fi
  done < <(kubectl get pods -n diameter-client -l app.kubernetes.io/name=diameter-client -o json | \
    jq -r '.items[].metadata.name')

  if [ "$FAILED" == 1 ]; then
    FAILED=0
    continue
  fi
  break

  sleep 5
done
