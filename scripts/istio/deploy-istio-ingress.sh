#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

export DEFAULT_OVERRIDES="$DIR/overrides/default.yaml"
source "$DIR/version-support.sh"

TMP_FILE=$(mktemp /tmp/deploy-istio.XXXXXX)
touch "$TMP_FILE"
trap 'rm "$TMP_FILE"' EXIT

kubectl apply -f "$DIR/istio-ingress-ns.yaml"
if [[ ${MULTICLUSTER_NETWORK:-} != "" ]]; then
  kubectl label namespace istio-ingress "topology.istio.io/network=${MULTICLUSTER_NETWORK}"
fi
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace istio-ingress

if [[ ${PULLSECRET:-} != "" ]]; then
  kubectl apply -f "$PULLSECRET" --namespace istio-ingress
fi

helm upgrade istio-ingress \
  "$RELEASE_PATH/manifests/charts/gateways/istio-ingress" \
  --install \
  --namespace=istio-ingress "${VALUES_OPTS[@]}" "$@"

while true; do
  LOAD_BALANCER=$(kubectl get service istio-ingressgateway \
    --namespace istio-ingress \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [ -n "$LOAD_BALANCER" ]; then
    break
  fi
  LOAD_BALANCER=$(kubectl get service istio-ingressgateway \
    --namespace istio-ingress \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  if [ -n "$LOAD_BALANCER" ]; then
    break
  fi
  sleep 5
done

echo "$LOAD_BALANCER" > load-balancer.value
