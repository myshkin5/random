#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [[ ${RELEASE_PATH:-} == "" ]]; then
  echo "RELEASE_PATH is undefined"
  exit 1
fi

if [ ! -d "$RELEASE_PATH" ]; then
  echo "RELEASE_PATH ($RELEASE_PATH) is not found"
  exit 1
fi

if [[ ${OVERRIDES:-} == "" ]]; then
  OVERRIDES="$DIR/overrides/default.yaml"
  echo "Defaulting overrides to $OVERRIDES"
fi

TMP_FILE=$(mktemp /tmp/deploy-istio.XXXXXX)
touch "$TMP_FILE"
trap 'rm "$TMP_FILE"' EXIT

kubectl apply -f "$DIR/istio-ns.yaml"
if [[ ${MULTICLUSTER_NETWORK:-} != "" ]]; then
  kubectl label namespace istio-system "topology.istio.io/network=${MULTICLUSTER_NETWORK}"
fi
kubectl apply -f ../private-resources/aspenmesh-istio-private-pr-pull-secret.yaml \
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
BASE_NAME=istio-base
if [ -d "$BASE_CHART" ]; then
  VER=$(grep -e "^version:" "$RELEASE_PATH/manifests/charts/base/Chart.yaml" |
    awk '{ print $2 }')
  MINOR_VER=${VER:0:3}
  if [[ $VER =~ .*-am.* ]]; then
    AM_RELEASE=true
  fi
  case $MINOR_VER in
    1.6)
      CRD_COUNT=36
      ;;
    1.9)
      if [ $AM_RELEASE == "true" ]; then
        CRD_COUNT=23
      else
        CRD_COUNT=12
      fi
      ;;
    *)
      echo "Unknown minor version"
      exit 1
      ;;
  esac
else
  MINOR_VER=1.5
  BASE_CHART="$RELEASE_PATH/install/kubernetes/helm/istio-init"
  BASE_NAME=istio-init
  CRD_COUNT=31
fi

AM_VALUES="$RELEASE_PATH/install/kubernetes/helm/istio/values-aspenmesh.yaml"
if [[ -f $AM_VALUES ]]; then
  VALUES_OPTS=("--values=$AM_VALUES")
fi
VALUES_OPTS+=("--values=$OVERRIDES")

if [[ "$RELEASE_PATH" =~ -(PR|pr) ]]; then
  VALUES_OPTS+=("--set=global.hub=quay.io/aspenmesh/releases-pr")
  VALUES_OPTS+=("--set=global.publicImagesHub=quay.io/aspenmesh/am-istio-pr")
fi
if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  OPENSHIFT=true
  VALUES_OPTS+=("--values=$DIR/cni-overrides.yaml")
else
  OPENSHIFT=false
fi

SKIP_CRDS=()
if [ -d "$BASE_CHART/crds" ]; then
  kubectl apply -f "$BASE_CHART/crds"
  SKIP_CRDS=("--skip-crds")
fi

VALIDATION=""
if [[ ${IN_PLACE_UPGRADE_1_9:-} == "true" ]]; then
  VALIDATION="--set=global.configValidation=false"
fi

helm upgrade $BASE_NAME "$BASE_CHART" \
  --install $VALIDATION \
  --namespace=istio-system "${VALUES_OPTS[@]}" "${SKIP_CRDS[@]}" "$@"

if [[ $OPENSHIFT == "true" ]]; then
  CNI_CHART="$RELEASE_PATH/manifests/charts/istio-cni"
  if [[ $MINOR_VER == "1.5" ]]; then
    CNI_CHART="$RELEASE_PATH/install/kubernetes/helm/istio-cni"
  fi
  if [[ -d "$CNI_CHART" ]]; then
    helm upgrade istio-cni "$CNI_CHART" \
      --install \
      --namespace=kube-system \
      --set components.cni.enabled=true "${VALUES_OPTS[@]}" "$@"
  fi
fi

if [[ ${PULLSECRET:-} != "" ]]; then
  kubectl apply -f "$PULLSECRET" --namespace istio-system
fi

while true; do
  COUNT=$(kubectl get crds |
    grep -c 'istio.io\|cert-manager.io\|aspenmesh.io') || true
  if (( COUNT >= CRD_COUNT )); then
    break
  fi
  sleep 5
done

if [ $MINOR_VER == "1.5" ]; then
  helm upgrade istio "$RELEASE_PATH/install/kubernetes/helm/istio" \
    --install \
    --namespace=istio-system "${VALUES_OPTS[@]}" "$@"
else
  helm upgrade istiod \
    "$RELEASE_PATH/manifests/charts/istio-control/istio-discovery" \
    --install \
    --namespace=istio-system "${VALUES_OPTS[@]}" "$@"

  if [[ ${IN_PLACE_UPGRADE_1_9:-} == "true" ]]; then
    helm upgrade $BASE_NAME "$BASE_CHART" \
      --set=global.configValidation=true \
      --namespace=istio-system "${VALUES_OPTS[@]}" "$@"
  fi

  helm upgrade istio-ingress \
    "$RELEASE_PATH/manifests/charts/gateways/istio-ingress" \
    --install \
    --namespace=istio-system "${VALUES_OPTS[@]}" "$@"
fi

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
done

echo "$LOAD_BALANCER" > load-balancer.value

ANALYSIS_CHART="$RELEASE_PATH/samples/aspenmesh/analysis-emulator"
if [[ $MINOR_VER == "1.5" ]]; then
  ANALYSIS_CHART="$RELEASE_PATH/samples/aspenmesh/gcb-emulator"
fi
if [ -d "$ANALYSIS_CHART" ]; then
  kubectl apply -f "$DIR/analysis-emulator-ns.yaml"
  helm upgrade analysis-emulator "$ANALYSIS_CHART" \
    --install \
    --namespace=analysis-emulator "${VALUES_OPTS[@]}" "$@"
fi

if [[ ${CHECK_READY:-} != "false" ]]; then
  kubectl apply -f "$DIR/ready.yaml"
  kubectl apply -f ../private-resources/aspenmesh-istio-private-pr-pull-secret.yaml \
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
