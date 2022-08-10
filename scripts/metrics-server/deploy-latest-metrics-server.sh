#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  OVERRIDES=$DIR/openshift-overrides.yaml
else
  OVERRIDES=$DIR/default-overrides.yaml
fi

LATEST=$(gh release list --repo github.com/kubernetes-sigs/metrics-server \
  | grep 'helm-chart.*Latest' | cut -f1 | cut -d- -f5)
ARCHIVE="metrics-server-$LATEST.tgz"
DOWNLOAD="https://github.com/kubernetes-sigs/metrics-server/releases/download/metrics-server-helm-chart-$LATEST/$ARCHIVE"

curl --location --output "$ARCHIVE" "$DOWNLOAD"

rm -rf metrics-server
tar xfz "$ARCHIVE"

helm upgrade metrics-server ./metrics-server --namespace kube-system --install \
  --values="$OVERRIDES"
