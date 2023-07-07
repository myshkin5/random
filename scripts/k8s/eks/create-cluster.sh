#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

INSTANCE_TYPE=${INSTANCE_TYPE:=t3a.large}
NODE_COUNT=${NODE_COUNT:=5}
SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY:="$HOME/.ssh/id_ed25519_aws_dev.pub"}
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
  --ssh-access \
  --ssh-public-key="$SSH_PUBLIC_KEY" \
  --external-dns-access \
  --kubeconfig="$KUBECONFIG"

"$DIR/../../metrics-server/deploy-metrics-server.sh"

aws cloudformation describe-stacks --stack-name "eksctl-$NAME-cluster" \
  | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="VPC") | .OutputValue' > vpc-id.value

aws cloudformation describe-stacks --stack-name "eksctl-$NAME-cluster" \
  | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="SubnetsPublic") | .OutputValue' \
  | cut -d , -f 1 > public-subnet-id.value
