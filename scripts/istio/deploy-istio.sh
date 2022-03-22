#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

export DEFAULT_OVERRIDES="$DIR/overrides/default.yaml"
source "$DIR/version-support.sh"

TMP_FILE=$(mktemp /tmp/deploy-istio.XXXXXX)
touch "$TMP_FILE"
trap 'rm "$TMP_FILE"' EXIT

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

VALIDATION=""
if [[ ${IN_PLACE_UPGRADE_1_9:-} == "true" ]]; then
  VALIDATION="--set=global.configValidation=false"
fi

helm upgrade istio-base "$BASE_CHART" \
  --install $VALIDATION \
  --namespace=istio-system "${VALUES_OPTS[@]}" "${SKIP_CRDS[@]}" "$@"

if [[ $OPENSHIFT == "true" ]]; then
  CNI_VALUES_OPTS=("${VALUES_OPTS[@]}")
  if [[ $AM_RELEASE == "false" ]]; then
    CNI_VALUES_OPTS+=("--values=$DIR/overrides/open-source-cni-values.yaml")
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

if [[ ${IN_PLACE_UPGRADE_1_9:-} == "true" ]]; then
  helm upgrade istio-base "$BASE_CHART" \
    --set=global.configValidation=true \
    --namespace=istio-system "${VALUES_OPTS[@]}" "$@"
fi

helm upgrade istio-ingress \
  "$RELEASE_PATH/manifests/charts/gateways/istio-ingress" \
  --install \
  --namespace=istio-system "${VALUES_OPTS[@]}" "$@"

kubectl get namespace --selector=istio-injection=enabled | tail -n +2 | while read -r NS _; do
  kubectl get deployment --namespace "$NS" -o name | while read -r DEPLOYMENT; do
    kubectl rollout restart --namespace "$NS" "$DEPLOYMENT"
    kubectl rollout status --namespace "$NS" "$DEPLOYMENT" --watch=true
  done
done

while true; do
  LOAD_BALANCER=$(kubectl get service istio-ingressgateway \
    --namespace istio-system \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  if [ -n "$LOAD_BALANCER" ]; then
    break
  fi
  LOAD_BALANCER=$(kubectl get service istio-ingressgateway \
    --namespace istio-system \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  if [ -n "$LOAD_BALANCER" ]; then
    break
  fi
  sleep 5
done

echo "$LOAD_BALANCER" > load-balancer.value

ANALYSIS_CHART="$RELEASE_PATH/samples/aspenmesh/analysis-emulator"
if [ -d "$ANALYSIS_CHART" ]; then
  kubectl apply -f "$DIR/analysis-emulator-ns.yaml"
  helm upgrade analysis-emulator "$ANALYSIS_CHART" \
    --install \
    --namespace=analysis-emulator "${VALUES_OPTS[@]}" "$@"
fi

if [[ ${CHECK_READY:-} != "false" ]]; then
  kubectl apply -f "$DIR/ready.yaml"
  kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
    --namespace istio-ready
  if [[ $OPENSHIFT == "true" ]]; then
    kubectl apply -f "$DIR/net-attach-def.yaml" \
      --namespace istio-ready
  fi

  dots() {
    while [ -f "$TMP_FILE" ]; do
      echo -n .
      sleep 10
    done
  }

  echo "http://$LOAD_BALANCER/status/200"
  set +x
  date
  echo "Time: 1 min 2 min 3 min 4 min 5 min 6 min 7 min"
  dots &
  while true; do
    STATUS=$(curl --silent \
      --output /dev/null \
      --write-out "%{http_code}\n" \
      "http://$LOAD_BALANCER/status/200" || true)
    if [[ $STATUS == 200 ]]; then
      break
    fi
    sleep 5
  done
  echo
  date
  set -x

  kubectl delete namespace istio-ready
fi
