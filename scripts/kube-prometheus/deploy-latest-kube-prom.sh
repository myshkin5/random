#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  OVERRIDES=$DIR/openshift-overrides.yaml
else
  OVERRIDES=$DIR/default-overrides.yaml
fi

LATEST=$(curl --silent "https://api.github.com/repos/prometheus-operator/kube-prometheus/releases/latest" \
  | jq -r '.tag_name' | cut -d- -f5)
ARCHIVE="kube-prometheus-$LATEST.tar.gz"
DOWNLOAD="https://github.com/prometheus-operator/kube-prometheus/archive/refs/tags/$LATEST.tar.gz"

curl --location --output "$ARCHIVE" "$DOWNLOAD"

rm -rf kube-prometheus
mkdir kube-prometheus
tar xfz "$ARCHIVE" --directory kube-prometheus --strip-components 1

# HACK: `apply` would be preferred here but one of the CRDs is too big
kubectl create -f kube-prometheus/manifests/setup

until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

kubectl apply -f kube-prometheus/manifests
kubectl apply -f "$DIR/prometheus-clusterRole.yaml"
