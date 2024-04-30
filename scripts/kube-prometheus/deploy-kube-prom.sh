#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [ "${SKIP_KUBE_PROM:-}" == "true" ]; then
  echo "SKIP_KUBE_PROM is set. Exiting without installing kube-prom"
  exit 0
fi

source "$DIR/../helm/commands.sh"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl apply -f "$DIR/namespace.yaml"

CHART=prometheus-community/kube-prometheus-stack
if [ -z "${KUBE_PROM_VERSION:-}" ]; then
  KUBE_PROM_VERSION=$(helm search repo prometheus-community --versions | \
    grep "^$CHART" | head -1 | cut -f 2 | tr -d ' ') || true
fi

export KUBE_PROM_VALUES="--set=prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false:\
  --set=prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false:${KUBE_PROM_VALUES:-}"

echo "Installing $CHART v$KUBE_PROM_VERSION"
helm-upgrade prometheus "$CHART" \
  "${KUBE_PROM_VALUES:-}" --namespace=monitoring --version "$KUBE_PROM_VERSION"
