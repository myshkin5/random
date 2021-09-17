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

kubectl apply -f "$DIR/external-vm.yaml"

mkdir -p external-vm-cert

"$RELEASE_PATH/bin/istioctl" x workload entry configure \
  -f "$DIR/external-vm-workloadgroup.yaml" \
  -o external-vm-cert \
  --clusterID Kubernetes

echo "$(dig +short "$(cat east-west-load-balancer.value)" | paste -s -d, -) istiod.istio-system.svc" > \
  external-vm-cert/hosts

# TODO: scp cert to vm and start sidecar
