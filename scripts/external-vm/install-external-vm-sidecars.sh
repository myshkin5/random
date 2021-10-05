#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/../istio/version-support.sh"

INSTANCE_COUNT=${INSTANCE_COUNT:=1}

kubectl apply -f "$DIR/external-vm.yaml"
kubectl apply -f "$DIR/external-vm-workloadgroup.yaml"

ISTIOD_IP=$(dig +short "$(cat east-west-load-balancer.value)" | head -1)

for (( INST_ITER=0; INST_ITER<INSTANCE_COUNT; INST_ITER++ )); do
  export INST_ITER
  CERT=external-vm-cert-$INST_ITER
  rm -rf "$CERT"
  mkdir -p "$CERT"

  "$RELEASE_PATH/bin/istioctl" x workload entry configure \
    -f "$DIR/external-vm-workloadgroup.yaml" \
    -o "$CERT" \
    --clusterID Kubernetes \
    --autoregister \
    --ingressIP "$ISTIOD_IP"

  envsubst \$INST_ITER < "$DIR/external-vm-sidecar.sh" > "$CERT/external-vm-sidecar.sh"
  chmod +x "$CERT/external-vm-sidecar.sh"
  tar cfz "$CERT.tgz" "$CERT"

  PUBLIC_IP=$(cat external-vm-public-ip-$INST_ITER.value)
  scp -i "$HOME/.ssh/id_ed25519_aws_dev" "$CERT.tgz" "ubuntu@$PUBLIC_IP:"

  ssh -i "$HOME/.ssh/id_ed25519_aws_dev" "ubuntu@$PUBLIC_IP" -t "tar xfz $CERT.tgz"

  ssh -i "$HOME/.ssh/id_ed25519_aws_dev" "ubuntu@$PUBLIC_IP" \
    -t "sudo ./external-vm-cert-$INST_ITER/external-vm-sidecar.sh $ISTIO_PATCH_VERSION"
done
