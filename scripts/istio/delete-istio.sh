#!/bin/bash

set -xeuEo pipefail

kubectl delete ns bookinfo || true

kubectl delete ns diameter-client || true
kubectl delete ns diameter-server || true

kubectl delete ns http-client || true
kubectl delete ns http-server || true

kubectl delete ns packet-inspector-benchmark || true

kubectl delete ns analysis-emulator || true
kubectl delete ns analysis-emulator-2 || true
kubectl delete ns test-ns || true

kubectl delete ns istio-ready || true

kubectl delete ns fortio || true

helm delete -n kube-system istio-cni || true

kubectl delete ns istio-ingress || true
kubectl delete ns istio-system || true

kubectl get crds | grep -e istio.io -e aspenmesh.io -e cert-manager.io | while read -r crd _; do
  kubectl delete crd "$crd"
done || true

kubectl get clusterrole | grep -e istio -e aspenmesh -e aspen-mesh -e dns-controller | while read -r role _; do
  kubectl delete clusterrole "$role"
done || true

kubectl get clusterrolebinding | grep -e istio -e aspenmesh -e aspen-mesh -e dns-controller | while read -r binding _; do
  kubectl delete clusterrolebinding "$binding"
done || true

kubectl get validatingwebhookconfiguration | grep -e istio | while read -r config _; do
  kubectl delete validatingwebhookconfiguration "$config"
done || true

kubectl get mutatingwebhookconfiguration | grep -e istio | while read -r config _; do
  kubectl delete mutatingwebhookconfiguration "$config"
done || true

for ns in $(kubectl get ns -o name | cut -d/ -f2 | grep -e "^bookinfo-[0-9]*-[0-9]*$"); do
  kubectl delete ns "$ns"
done || true

for ns in $(kubectl get ns -o name | cut -d/ -f2 | grep -e "^test-ns-[0-9]*-[0-9]*$"); do
  kubectl delete ns "$ns"
done || true

for ns in $(kubectl get ns -o name | cut -d/ -f2 | grep -e "^lua-filter-[0-9]*-[0-9]*$"); do
  kubectl delete ns "$ns"
done || true

kubectl delete validatingwebhookconfiguration aspen-mesh-controlplane || true
kubectl delete validatingwebhookconfiguration aspen-mesh-secure-ingress || true
kubectl delete validatingwebhookconfiguration traffic-claim-enforcer || true

set +x

FOUND=false
while read -r NS _; do
  if [ "$FOUND" == "false" ]; then
    echo "Found namespace(s) with Istio injection. Execute the following to clean up:"
    FOUND=true
  fi
  echo "  kubectl delete namespace $NS"
done < <(kubectl get namespace --selector=istio-injection=enabled | tail -n +2)
if [ "$FOUND" == "true" ]; then
  exit 1
fi

echo "Istio successfully deleted"
