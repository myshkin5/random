#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

export OVERRIDES="$DIR/overrides/east-west-gw-default.yaml"
source "$DIR/../istio/version-support.sh"

if [[ $ISTIO_MINOR_VERSION == "1.9" ]]; then
  # Gateway auto-injection (https://istio.io/latest/docs/setup/additional-setup/gateway/)
  # doesn't work in 1.9
  VALUES_OPTS+=("--set gateways.istio-ingressgateway.injectionTemplate=\"\"")
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
