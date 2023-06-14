#!/usr/bin/env bash

set -xEeuo pipefail

if [ -z "${GW_API_VERSION:-}" ]; then
  GW_API_VERSION=$(curl --silent "https://api.github.com/repos/kubernetes-sigs/gateway-api/releases/latest" \
    | jq -r '.tag_name' | cut -d- -f5)
fi

MANIFEST="https://github.com/kubernetes-sigs/gateway-api/releases/download/$GW_API_VERSION/standard-install.yaml"

kubectl apply -f "$MANIFEST"
