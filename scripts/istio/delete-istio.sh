#!/bin/bash

set -xeuEo pipefail

kubectl delete ns bookinfo || true

helm delete -n packet-inspector-benchmark packet-inspector-benchmark-client || true
helm delete -n packet-inspector-benchmark packet-inspector-benchmark-server || true
helm delete -n analysis-emulator analysis-emulator || true
kubectl delete ns packet-inspector-traffic || true
kubectl delete ns packet-inspector-traffic-client || true
kubectl delete ns packet-inspector-traffic-server || true
kubectl delete ns packet-inspector-benchmark || true
kubectl delete ns analysis-emulator || true
kubectl delete ns test-ns || true

kubectl delete -f istio-ready.yaml || true
kubectl delete ns istio-ready || true

helm delete -n istio-system istio-egress || true
helm delete -n istio-system istio-ingress || true
helm delete -n istio-system istiod || true
helm delete -n kube-system istio-cni || true
helm delete -n istio-system istio-base || true

helm delete -n istio-system istio || true
helm delete -n istio-system istio-init || true
kubectl delete ns istio-system || true

kubectl get crds | grep -e istio.io -e aspenmesh.io -e cert-manager.io | while read -r crd _; do
  kubectl delete crd "$crd"
done || true

kubectl delete validatingwebhookconfiguration aspen-mesh-controlplane || true
kubectl delete validatingwebhookconfiguration aspen-mesh-secure-ingress || true
kubectl delete validatingwebhookconfiguration traffic-claim-enforcer || true
