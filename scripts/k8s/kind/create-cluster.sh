#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [ -z "${KIND_VERSION:-}" ]; then
  KIND_VERSION=$(curl --silent "https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" \
    | jq -r '.tag_name' | cut -d- -f5)
fi

ARCH=amd64
if [[ $(uname --processor) == "aarch64" ]]; then
  ARCH=arm64
fi

BINARY="kind-linux-$ARCH-$KIND_VERSION"
DOWNLOAD="https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-$ARCH"

curl --location --output "$BINARY" "$DOWNLOAD"
chmod +x "$BINARY"
mkdir -p bin
rm -f bin/kind
ln -s "../$BINARY" bin/kind

KIND_OPTS=()
if [ -n "${K8S_VERSION:-}" ]; then
  KIND_VERSION=$(kind --version | cut -f3 -d\ )
  IMAGE=$(curl --silent "https://github.com/kubernetes-sigs/kind/releases/tag/v$KIND_VERSION" | \
    grep "^<li>$K8S_VERSION:" | sed -e 's#.*<code>\(.*\)</code>.*#\1#')
  KIND_OPTS+=("--image" "$IMAGE")
fi

kind create cluster --name "$NAME" --config "$KIND_CONFIG" "${KIND_OPTS[@]}"

kubectl get configmap kube-proxy -n kube-system -o yaml | \
  sed -e "s/strictARP: false/strictARP: true/" -e "s/mode: iptables/mode: ipvs/" | \
  kubectl apply -f - -n kube-system

if [ -z "${METALLB_VERSION:-}" ]; then
  METALLB_VERSION=$(curl --silent "https://api.github.com/repos/metallb/metallb/releases/latest" \
    | jq -r '.tag_name' | cut -d- -f5)
fi

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/$METALLB_VERSION/config/manifests/metallb-frr.yaml"
kubectl wait pods -n metallb-system -l app=metallb --for condition=Ready --timeout=5m
kubectl apply -f "$DIR/metallb-l2ad.yaml"

METALLB_POOL=${METALLB_POOL:-"$DIR/metallb-pool.yaml"}
kubectl apply -f "$METALLB_POOL"

"$DIR/../../metrics-server/deploy-metrics-server.sh"
"$DIR/../../kube-prometheus/deploy-kube-prom.sh"
"$DIR/../../gateway-api/deploy-gateway-api.sh"
