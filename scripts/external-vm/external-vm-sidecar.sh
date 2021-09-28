#!/usr/bin/env bash

set -xeuEo pipefail

if [ $# != 1 ]; then
  echo "Patch version not specified"
  echo "Usage: $0 <patch version>"
  exit 1
fi
PATCH_VER=$1

ISTIOCTL_TGZ=istioctl-$PATCH_VER-linux-amd64.tar.gz
curl -L -O "https://storage.googleapis.com/istio-release/releases/$PATCH_VER/$ISTIOCTL_TGZ"
tar xfz "$ISTIOCTL_TGZ"
mv istioctl /usr/local/bin
rm "$ISTIOCTL_TGZ"

cd external-vm-cert

mkdir -p /etc/certs
cp root-cert.pem /etc/certs

mkdir -p /var/run/secrets/tokens
cp istio-token /var/run/secrets/tokens/istio-token

curl -LO "https://storage.googleapis.com/istio-release/releases/$PATCH_VER/deb/istio-sidecar.deb"
dpkg -i istio-sidecar.deb

cp cluster.env /var/lib/istio/envoy/cluster.env

# For additional debug logs
#echo "ISTIO_AGENT_FLAGS=\"--log_output_level=dns:debug --proxyLogLevel=debug\"" >> /var/lib/istio/envoy/cluster.env

cp mesh.yaml /etc/istio/config/mesh

cat hosts >> /etc/hosts

mkdir -p /etc/istio/proxy
chown -R istio-proxy \
  /var/lib/istio \
  /etc/certs \
  /etc/istio/proxy \
  /etc/istio/config \
  /var/run/secrets

systemctl start istio
