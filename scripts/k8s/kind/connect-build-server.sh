#!/usr/bin/env bash

set -xeuEo pipefail

if [ -z "$BUILD_SERVER_SSH_KEY_FILE" ]; then
  >&2 echo "BUILD_SERVER_SSH_KEY_FILE must be defined"
  exit 1
fi

if [ -z "$BUILD_SERVER" ]; then
  >&2 echo "BUILD_SERVER must be defined"
  exit 1
fi

if [ -z "$BUILD_USER" ]; then
  >&2 echo "BUILD_USER must be defined"
  exit 1
fi

if [[ $PWD != $HOME/workspace/clusters/* ]]; then
  >&2 echo "Current working directory must be in clusters directory"
  exit 1
fi

REL_PATH=${PWD:(( ${#HOME}+1 ))}

scp -i "$BUILD_SERVER_SSH_KEY_FILE" "$BUILD_USER@$BUILD_SERVER:$REL_PATH/.kubeconfig" .

K8S_URL=$(yq ".clusters[0].cluster.server" .kubeconfig)
K8S_PORT=$(echo "$K8S_URL" | cut -d: -f3)

echo ssh -N -i "$BUILD_SERVER_SSH_KEY_FILE" -L "$K8S_PORT:localhost:$K8S_PORT" "$BUILD_USER@$BUILD_SERVER" \&
