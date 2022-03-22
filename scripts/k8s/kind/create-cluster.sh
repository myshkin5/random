#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

kind create cluster --name "$NAME" --config "$KIND_CONFIG"

kubectl get configmap kube-proxy -n kube-system -o yaml | \
  sed -e "s/strictARP: false/strictARP: true/" -e "s/mode: iptables/mode: ipvs/" | \
  kubectl apply -f - -n kube-system

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist \
  --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

METALLB_CONFIGMAP=${METALLB_CONFIGMAP:-"$DIR/metallb-cm.yaml"}
kubectl apply -f "$METALLB_CONFIGMAP"

kubectl apply -f "$DIR/../kubernetes-sigs-metrics-server-v0.4.2-components.yaml"
