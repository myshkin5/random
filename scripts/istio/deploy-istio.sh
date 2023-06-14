#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../helm/commands.sh"
source "$DIR/version-support.sh"

mkdir -p bin
rm -f bin/istioctl
ln -s "$RELEASE_PATH/bin/istioctl" bin/

kubectl apply -f "$DIR/istio-ns.yaml"
if [[ ${MULTICLUSTER_NETWORK:-} != "" ]]; then
  kubectl label namespace istio-system "topology.istio.io/network=${MULTICLUSTER_NETWORK}"
fi
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace istio-system

if [[ ${UPDATE_CA_CERT:-} != "false" ]]; then
  if [[ ${CA_CERT_DIR:-} == "" ]]; then
    "$DIR/generate-ca-cert.sh"
    CA_CERT_DIR=./ecc
  fi
  kubectl create secret generic cacerts -n istio-system \
    --from-file="$CA_CERT_DIR/ca-cert.pem" \
    --from-file="$CA_CERT_DIR/ca-key.pem" \
    --from-file="$CA_CERT_DIR/root-cert.pem" \
    --from-file="$CA_CERT_DIR/cert-chain.pem" \
    --dry-run -o yaml |
    kubectl apply -f -
fi

BASE_CHART="$RELEASE_PATH/manifests/charts/base"
SKIP_CRDS=()
if [ -d "$BASE_CHART/crds" ]; then
  kubectl apply -f "$BASE_CHART/crds"
  SKIP_CRDS=("--skip-crds")
fi

helm-upgrade istio-base "$BASE_CHART" "${ISTIO_BASE_VALUES:-}" \
  --namespace=istio-system "${SKIP_CRDS[@]}"

if [[ $OPENSHIFT == "true" || ${CNI_ENABLED:-} == "true" ]]; then
  helm-upgrade istio-cni "$RELEASE_PATH/manifests/charts/istio-cni" \
    "${ISTIO_CNI_VALUES:-"$DIR/config/cni/default.yaml"}" \
    --namespace=kube-system
fi

while true; do
  COUNT=$(kubectl get crds |
    grep -c 'istio.io\|cert-manager.io\|aspenmesh.io') || true
  if (( COUNT > CRD_COUNT )); then
    echo "Expected only $CRD_COUNT CRDs, got too many ($COUNT)"
    exit 1
  fi
  if [[ "$COUNT" == "$CRD_COUNT" ]]; then
    break
  fi
  sleep 5
done

helm-upgrade istiod "$RELEASE_PATH/manifests/charts/istio-control/istio-discovery" \
  "${ISTIOD_VALUES:-"$DIR/config/istiod/default.yaml"}" \
  --namespace=istio-system

kubectl get namespace --selector=istio-injection=enabled | tail -n +2 | while read -r NS _; do
  kubectl get deployment --namespace "$NS" -o name | while read -r DEPLOYMENT; do
    kubectl rollout restart --namespace "$NS" "$DEPLOYMENT"
    kubectl rollout status --namespace "$NS" "$DEPLOYMENT" --watch=true
  done
done
