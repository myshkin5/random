#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

TMP_FILE=$(mktemp /tmp/standard-cluster.XXXXXX)
touch "$TMP_FILE"
trap 'rm "$TMP_FILE"' EXIT

INSTANCE_TYPE=${INSTANCE_TYPE:=t3a.large}
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
    --node-count=5 \
    --zones=us-west-2b \
    --name="$NAME" \
    --authorization RBAC \
    --ssh-public-key="$HOME/.ssh/id_rsa_dev_k8s.pub" \
    --topology=private \
    --admin-access="$my_ip/32" \
    --networking=flannel

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

set +x
date
echo "Time: 1 min 2 min 3 min 4 min 5 min 6 min 7 min"
dots &
while true; do
  RET=0
  kops validate cluster > /dev/null 2>&1 || RET=$?
  if [[ $RET == 0 ]]; then
    break
  fi
  sleep 5
done
echo
date
set -x

kubectl apply -f "$DIR/kubernetes-sigs-metrics-server-v0.3.7-components-kops.yaml"
