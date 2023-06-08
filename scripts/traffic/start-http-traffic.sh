#!/bin/bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if (( $(kubectl get namespace | grep -c http-server) == 0 )); then
  kubectl create namespace http-server
fi
kubectl label namespace http-server istio-injection=enabled
#kubectl label namespace http-server istio-injection-
#kubectl label namespace http-server istio.io/dataplane-mode=ambient
kubectl label namespace http-server istio.io/dataplane-mode-

if (( $(kubectl get namespace | grep -c http-client) == 0 )); then
  kubectl create namespace http-client
fi
kubectl label namespace http-client istio-injection=enabled
#kubectl label namespace http-client istio-injection-
#kubectl label namespace http-client istio.io/dataplane-mode=ambient
kubectl label namespace http-client istio.io/dataplane-mode-

if (( $(kubectl get namespace | grep -c openshift) > 0 )); then
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace http-server
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" --namespace http-client
fi
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace http-server
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace http-client

helm upgrade http-server "$DIR/../../charts/http-server" --install --namespace http-server "$@"
helm upgrade http-client "$DIR/../../charts/http-client" --install --namespace http-client "$@"

POD=""
while true; do
  if [ "$POD" == "" ]; then
    POD=$(kubectl get pod -n http-client \
      -l app.kubernetes.io/name=http-client \
      -o jsonpath='{.items[0].metadata.name}' || true)
    if [ "$POD" == "" ]; then
      sleep 5
      continue
    fi
  fi
  ORIGIN=$(kubectl exec -n http-client -c http-client "$POD" \
    -- curl --silent http://http-server.http-server.svc.cluster.local:8000/get | jq -r ".origin") || true
  if [[ "$ORIGIN" == "127.0.0.1" ]]; then
    break
  fi
  sleep 5
done

kubectl cp ~/workspace/hey_linux_amd64 -c http-client "http-client/$POD:hey"
kubectl exec -n http-client -c http-client "$POD" -- chmod +x /hey
kubectl exec -n http-client -c http-client "$POD" \
  -- ./hey -n 1000 -q 10 -c 10 http://http-server.http-server.svc.cluster.local:8000/get
