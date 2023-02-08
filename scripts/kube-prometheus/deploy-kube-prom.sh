#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [ -z "${KUBE_PROM_VERSION:-}" ]; then
  KUBE_PROM_VERSION=$(curl --silent "https://api.github.com/repos/prometheus-operator/kube-prometheus/releases/latest" \
    | jq -r '.tag_name' | cut -d- -f5)
fi

ARCHIVE="kube-prometheus-$KUBE_PROM_VERSION.tar.gz"
DOWNLOAD="https://github.com/prometheus-operator/kube-prometheus/archive/refs/tags/$KUBE_PROM_VERSION.tar.gz"

curl --location --output "$ARCHIVE" "$DOWNLOAD"

rm -rf kube-prometheus
mkdir kube-prometheus
tar xfz "$ARCHIVE" --directory kube-prometheus --strip-components 1

kubectl apply -f kube-prometheus/manifests/setup/*namespace.yaml

if [[ "${SKIP_CRDS:-false}" == "false" ]]; then
  # HACK: `apply` would be preferred here but one of the CRDs is too big
  kubectl create -f kube-prometheus/manifests/setup/*CustomResourceDefinition.yaml
fi

REMAINING=$(find kube-prometheus/manifests/setup -depth 1 \
  ! -name \*namespace.yaml ! -name \*CustomResourceDefinition.yaml)
if [[ -n "$REMAINING" ]]; then
  kubectl apply -f "$REMAINING"
fi

until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  F=kube-prometheus/manifests/prometheusAdapter-apiService.yaml
  if [[ ! -f $F ]]; then
    F=kube-prometheus/manifests/prometheus-adapter-apiService.yaml
  fi
  if [[ ! -f $F ]]; then
    echo "Can't find $F to remove insecureSkipTLSVerify"
    exit 1
  fi
  grep -v insecureSkipTLSVerify $F > hack-kube-prom-apiService.yaml
  mv hack-kube-prom-apiService.yaml $F
fi

kubectl apply -f kube-prometheus/manifests
kubectl apply -f "$DIR/prometheus-clusterRole.yaml"
