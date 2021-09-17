#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

INSTANCE_TYPE=${INSTANCE_TYPE:=t3a.large}
NODE_COUNT=${NODE_COUNT:=5}
VER_OPT=""
if [ -n "${K8S_VERSION:-}" ]; then
  VER_OPT="--version=$K8S_VERSION"
fi

date

eksctl create cluster \
  --name="$NAME" \
  $VER_OPT \
  --node-type="$INSTANCE_TYPE" \
  --nodes-min="$NODE_COUNT" \
  --nodes-max="$NODE_COUNT" \
  --ssh-public-key="$HOME/.ssh/id_rsa_dev_k8s.pub" \
  --external-dns-access \
  --kubeconfig="$KUBECONFIG"

kubectl apply -f "$DIR/../kubernetes-sigs-metrics-server-v0.4.2-components.yaml"

aws cloudformation describe-stacks --stack-name "eksctl-$NAME-cluster" \
  | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="VPC") | .OutputValue' > vpc-id.value

aws cloudformation describe-stacks --stack-name "eksctl-$NAME-cluster" \
  | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="SubnetsPublic") | .OutputValue' \
  | cut -d , -f 1 > public-subnet-id.value
