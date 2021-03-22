#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

INSTANCE_TYPE=${INSTANCE_TYPE:=t3a.large}
VER_OPT=""
if [ -n "${K8S_VERSION:-}" ]; then
  VER_OPT="--version=$K8S_VERSION"
fi

eksctl create cluster \
  --name="$NAME" \
  $VER_OPT \
  --node-type="$INSTANCE_TYPE" \
  --nodes-min=5 \
  --nodes-max=5 \
  --ssh-public-key="$HOME/.ssh/id_rsa_dev_k8s.pub" \
  --kubeconfig="$KUBECONFIG"

kubectl apply -f "$DIR/../kubernetes-sigs-metrics-server-v0.4.2-components.yaml"
