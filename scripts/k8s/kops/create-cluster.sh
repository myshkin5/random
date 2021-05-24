#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

TMP_FILE=$(mktemp /tmp/standard-cluster.XXXXXX)
touch "$TMP_FILE"
trap 'rm "$TMP_FILE"' EXIT

INSTANCE_TYPE=${INSTANCE_TYPE:=t3a.large}
NODE_COUNT=${NODE_COUNT:=5}
NETWORKING=${NETWORKING:=flannel}
VER_OPT=""
if [ -n "${K8S_VERSION:-}" ]; then
  VER_OPT="--kubernetes-version=$K8S_VERSION"
fi

date

my_ip=$(curl -s https://api.ipify.org)

kops create cluster \
    $VER_OPT \
    --master-size="$INSTANCE_TYPE" \
    --node-size="$INSTANCE_TYPE" \
    --node-count="$NODE_COUNT" \
    --zones=us-west-2b \
    --name="$NAME" \
    --authorization RBAC \
    --ssh-public-key="$HOME/.ssh/id_rsa_dev_k8s.pub" \
    --topology=private \
    --admin-access="$my_ip/32" \
    --networking="$NETWORKING"

EDITOR="$DIR/../../yq-merge-editor.sh $DIR/third-party-token-projection-merge.yaml" kops edit cluster --name "$NAME"
EDITOR="$DIR/../../yq-merge-editor.sh $DIR/ext-dns-merge.yaml" kops edit cluster --name "$NAME"
EDITOR="$DIR/../../yq-merge-editor.sh $DIR/metrics-server-merge.yaml" kops edit cluster --name "$NAME"
kops update cluster "$NAME" --yes
kops export kubecfg --admin=10000h0m0s

dots() {
  while [ -f "$TMP_FILE" ]; do
    echo -n .
    sleep 10
  done
}

kops validate cluster --wait 10m

kubectl apply -f "$DIR/kubernetes-sigs-metrics-server-v0.3.7-components-kops.yaml"
