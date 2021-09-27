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

kubectl apply -f "$DIR/external-vm.yaml"
kubectl apply -f "$DIR/external-vm-workloadgroup.yaml"

rm -rf external-vm-cert
mkdir -p external-vm-cert

ISTIOD_IP=$(dig +short "$(cat east-west-load-balancer.value)" | head -1)

"$RELEASE_PATH/bin/istioctl" x workload entry configure \
  -f "$DIR/external-vm-workloadgroup.yaml" \
  -o external-vm-cert \
  --clusterID Kubernetes \
  --autoregister \
  --ingressIP "$ISTIOD_IP"

cp "$DIR/external-vm-sidecar.sh" external-vm-cert
tar cfz external-vm-cert.tgz external-vm-cert

scp -i "$HOME/.ssh/id_ed25519_aws_dev" external-vm-cert.tgz \
  "ubuntu@$(cat external-vm-public-ip.value):"

ssh -i "$HOME/.ssh/id_ed25519_aws_dev" "ubuntu@$(cat external-vm-public-ip.value)" \
  -t "tar xfz external-vm-cert.tgz"

VER=$(grep -e "^version:" "$RELEASE_PATH/manifests/charts/base/Chart.yaml" | awk '{ print $2 }')
if [[ $VER == "1.1.0" ]]; then
  # Several Istio releases have an inaccurate chart version; use the
  # Istio-only manifest.yaml instead
  VER=$(grep -e "^version:" "$RELEASE_PATH/manifest.yaml" | awk '{ print $2 }')
fi
PATCH_VER=$(echo "$VER" | cut -d \. -f "1-3")

ssh -i "$HOME/.ssh/id_ed25519_aws_dev" "ubuntu@$(cat external-vm-public-ip.value)" \
  -t "sudo ./external-vm-cert/external-vm-sidecar.sh $PATCH_VER"
