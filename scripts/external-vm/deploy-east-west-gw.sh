#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [[ ${RELEASE_PATH:-} == "" ]]; then
  echo "RELEASE_PATH is undefined"
  exit 1
fi

if [ ! -d "$RELEASE_PATH" ]; then
  echo "RELEASE_PATH ($RELEASE_PATH) is not found"
  exit 1
fi

if [[ ${OVERRIDES:-} == "" ]]; then
  OVERRIDES="$DIR/overrides/east-west-gw-default.yaml"
  echo "Defaulting overrides to $OVERRIDES"
fi

VALUES_OPTS=("--values=$OVERRIDES")
if [[ "$RELEASE_PATH" =~ -(PR|pr) ]]; then
  VALUES_OPTS+=("--set=global.hub=quay.io/aspenmesh/releases-pr")
  VALUES_OPTS+=("--set=global.publicImagesHub=quay.io/aspenmesh/am-istio-pr")
fi
if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  VALUES_OPTS+=("--values=$DIR/../istio/overrides/cni.yaml")
fi

helm upgrade istio-east-west-ingress \
  "$RELEASE_PATH/manifests/charts/gateways/istio-ingress" \
  --install \
  --namespace=istio-system "${VALUES_OPTS[@]}" "$@"

while true; do
  LOAD_BALANCER=$(kubectl get service east-west-gw \
    --namespace istio-system \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [ -n "$LOAD_BALANCER" ]; then
    break
  fi
done

echo "$LOAD_BALANCER" > east-west-load-balancer.value

kubectl apply -f "$DIR/expose-istiod.yaml" --namespace istio-system
