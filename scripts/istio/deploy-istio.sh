#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

export DEFAULT_OVERRIDES="$DIR/overrides/default.yaml"
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

helm upgrade istio-base "$BASE_CHART" \
  --install \
  --namespace=istio-system "${VALUES_OPTS[@]}" "${SKIP_CRDS[@]}" "$@"

if [[ $OPENSHIFT == "true" ]]; then
  CNI_VALUES_OPTS=("${VALUES_OPTS[@]}")
  if [[ $AM_RELEASE == "false" ]]; then
    CNI_VALUES_OPTS+=("--values=$DIR/overrides/open-source-cni-values.yaml")
    CNI_VALUES_OPTS+=("--set=cni.privileged=true")
  fi
  helm upgrade istio-cni "$RELEASE_PATH/manifests/charts/istio-cni" \
    --install \
    --namespace=kube-system \
    --set components.cni.enabled=true "${CNI_VALUES_OPTS[@]}" "$@"
  if [[ $AM_RELEASE == "false" && $ISTIO_MINOR_VERSION == "1.11.5" ]]; then
    kubectl patch daemonset istio-cni-node -n kube-system \
      --patch-file "$DIR/patches/cni-daemonset-1.11.5.yaml"
  fi
fi

if [[ ${PULLSECRET:-} != "" ]]; then
  kubectl apply -f "$PULLSECRET" --namespace istio-system
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

helm upgrade istiod \
  "$RELEASE_PATH/manifests/charts/istio-control/istio-discovery" \
  --install \
  --namespace=istio-system "${VALUES_OPTS[@]}" "$@"

kubectl get namespace --selector=istio-injection=enabled | tail -n +2 | while read -r NS _; do
  kubectl get deployment --namespace "$NS" -o name | while read -r DEPLOYMENT; do
    kubectl rollout restart --namespace "$NS" "$DEPLOYMENT"
    kubectl rollout status --namespace "$NS" "$DEPLOYMENT" --watch=true
  done
done
