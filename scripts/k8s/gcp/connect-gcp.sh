#!/usr/bin/env bash

set -xeuEo pipefail

if [ -z "${GCP_PROJECT+x}" ]; then
  >&2 echo "GCP_PROJECT must be defined"
  exit 1
fi

if [ -z "${GCP_REGION+x}" ]; then
  >&2 echo "GCP_REGION must be defined"
  exit 1
fi

if [ -z "${GCP_ZONE+x}" ]; then
  >&2 echo "GCP_ZONE must be defined"
  exit 1
fi

if [ -z "${GCP_INTERNAL_IP+x}" ]; then
  >&2 echo "GCP_INTERNAL_IP must be defined"
  exit 1
fi

if [ -z "${GCP_BASTION+x}" ]; then
  >&2 echo "GCP_BASTION must be defined"
  exit 1
fi

if [ -z "${HTTPS_PROXY+x}" ]; then
  >&2 echo "HTTPS_PROXY must be defined"
  exit 1
fi

if [ -z "${KUBECONFIG+x}" ]; then
  >&2 echo "KUBECONFIG must be defined"
  exit 1
fi

# Needs to be set but not while we are connecting
PROXY_HOST=$(echo "$HTTPS_PROXY" | cut -d: -f1)
PROXY_PORT=$(echo "$HTTPS_PROXY" | cut -d: -f2)
SAVE_HTTPS_PROXY=$HTTPS_PROXY
unset HTTPS_PROXY

if [ "$PROXY_HOST" == "localhost" ]; then
  >&2 echo "HTTPS_PROXY must not specify localhost (use 127.0.0.1)"
  exit 1
fi

PID=$(pgrep -l -f ssh | \
  grep start-iap-tunnel | grep "$PROXY_PORT" | \
  awk '{ print $1 }' || true)
if [ -n "$PID" ]; then
  echo "Already connected"
  exit 1
fi

RET_CODE=0
gcloud components list --format=list --filter="name:gke-gcloud-auth-plugin" | grep "Not Installed" || RET_CODE=$?
if [ "$RET_CODE" -eq "0" ]; then
  >&2 echo "gke-gcloud-auth-plugin must be installed:"
  >&2 echo "  HTTPS_PROXY= gcloud components install gke-gcloud-auth-plugin"
  >&2 echo "  HTTPS_PROXY= gcloud components update"
  exit 1
fi

gcloud config set project "$GCP_PROJECT"

gcloud container clusters get-credentials \
  --project "$GCP_PROJECT" \
  --zone "$GCP_REGION" \
  --internal-ip "$GCP_INTERNAL_IP"

sleep 10 && echo "" && echo "Starting ssh tunnel (logout to disconnect)" &

gcloud beta compute ssh "$GCP_BASTION" \
  --tunnel-through-iap \
  --project "$GCP_PROJECT" \
  --zone "$GCP_ZONE" \
    -- -L"$PROXY_PORT:$SAVE_HTTPS_PROXY"
