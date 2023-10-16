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

if [ -z "$BUILD_KIND_IP" ]; then
  >&2 echo "BUILD_KIND_IP must be defined"
  exit 1
fi

if [[ $PWD != $HOME/workspace/clusters/* ]]; then
  >&2 echo "Current working directory must be in clusters directory"
  exit 1
fi

PID=$(pgrep -l -f ssh | \
  grep "$BUILD_USER@$BUILD_SERVER" | grep 443 | grep -v sudo | \
  awk '{ print $1 }' || true)
if [ -n "$PID" ]; then
  echo "Already connected"
  exit 1
fi

REL_PATH=${PWD:(( ${#HOME}+1 ))}
REMOTE_KUBECONFIG=${REMOTE_KUBECONFIG:-$REL_PATH/.kubeconfig}
scp -i "$BUILD_SERVER_SSH_KEY_FILE" "$BUILD_USER@$BUILD_SERVER:$REMOTE_KUBECONFIG" .kubeconfig

DOCKER_CIDR24=$(ssh -i "$BUILD_SERVER_SSH_KEY_FILE" "$BUILD_USER@$BUILD_SERVER" \
  docker network inspect -f json kind | jq -r '.[].IPAM.Config[0].Subnet' | cut -d\. -f1-3)
BUILD_CIDR24=$(echo "$BUILD_KIND_IP" | cut -d\. -f1-3)
if [[ "$BUILD_CIDR24" != "$DOCKER_CIDR24" ]]; then
  echo "Update BUILD_KIND_IP ($BUILD_KIND_IP) to use Docker network ($DOCKER_CIDR24)"
  exit 1
fi

K8S_URL=$(yq ".clusters[0].cluster.server" .kubeconfig)
K8S_PORT=$(echo "$K8S_URL" | cut -d: -f3)

sudo ifconfig lo0 alias "$BUILD_KIND_IP"

sudo ssh -N -i "$BUILD_SERVER_SSH_KEY_FILE" \
  -L "$K8S_PORT:localhost:$K8S_PORT" \
  -L "$BUILD_KIND_IP:80:$BUILD_KIND_IP:80" \
  -L "$BUILD_KIND_IP:443:$BUILD_KIND_IP:443" \
  -o ServerAliveInterval=14400 -o ServerAliveCountMax=0 \
  "$BUILD_USER@$BUILD_SERVER" > /dev/null 2>&1 &
