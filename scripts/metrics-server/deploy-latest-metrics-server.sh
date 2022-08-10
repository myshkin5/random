#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  OVERRIDES=$DIR/openshift-overrides.yaml
else
  OVERRIDES=$DIR/default-overrides.yaml
fi

LATEST=$(curl --silent https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest \
  | jq -r '.tag_name' | cut -d- -f5)
ARCHIVE="metrics-server-$LATEST.tgz"
DOWNLOAD="https://github.com/kubernetes-sigs/metrics-server/releases/download/metrics-server-helm-chart-$LATEST/$ARCHIVE"

curl --location --output "$ARCHIVE" "$DOWNLOAD"

rm -rf metrics-server
tar xfz "$ARCHIVE"

helm upgrade metrics-server ./metrics-server --namespace kube-system --install \
  --values="$OVERRIDES"
