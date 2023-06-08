#!/bin/bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

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
#kubectl label namespace diameter-server istio-injection=enabled
kubectl label namespace diameter-server istio-injection-
kubectl label namespace diameter-server istio.io/dataplane-mode=ambient
#kubectl label namespace diameter-server istio.io/dataplane-mode-

if (( $(kubectl get namespace | grep -c diameter-client) == 0 )); then
  kubectl create namespace diameter-client
fi
#kubectl label namespace diameter-client istio-injection=enabled
kubectl label namespace diameter-client istio-injection-
kubectl label namespace diameter-client istio.io/dataplane-mode=ambient
#kubectl label namespace diameter-client istio.io/dataplane-mode-

if (( $(kubectl get namespace | grep -c openshift) > 0 )); then
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace diameter-client
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace diameter-server
fi
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace diameter-client
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace diameter-server

helm upgrade diameter-client "$DIAM_CLIENT_CHART" --install --namespace diameter-client "$@"
helm upgrade diameter-server "$DIAM_SERVER_CHART" --install --namespace diameter-server "$@"

POD=""
while true; do
  if [ "$POD" == "" ]; then
    POD=$(kubectl get pod -n diameter-client \
      -l app.kubernetes.io/name=diameter-client \
      -o jsonpath='{.items[0].metadata.name}' || true)
    if [ "$POD" == "" ]; then
      sleep 5
      continue
    fi
  fi
  RET_CODE=0
  kubectl exec -n diameter-client -c diameter-client "$POD" \
    -- diameter-client -addr diameter-server.diameter-server:3868 -hello || RET_CODE=$?
  if [[ "$RET_CODE" == "0" ]]; then
    break
  fi
  sleep 5
done
