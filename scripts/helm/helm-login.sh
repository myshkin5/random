#!/usr/bin/env bash

set -xeuEo pipefail

if [ -z "${GCP_PROJECT+x}" ]; then
  >&2 echo "GCP_PROJECT must be defined"
  exit 1
fi

if [ -z "${GCP_PULL_SA_KEY+x}" ]; then
  >&2 echo "GCP_PULL_SA_KEY must be defined"
  exit 1
fi

if [ -z "${HELM_LOGIN_URL+x}" ]; then
  >&2 echo "HELM_LOGIN_URL must be defined"
  exit 1
fi

gcloud config set project "$GCP_PROJECT"
SECRET_VER=$(gcloud secrets versions list "$GCP_PULL_SA_KEY"  --limit 1 --format="csv[no-heading](name)")

SECRET=$(gcloud secrets versions access "$SECRET_VER" --secret="$GCP_PULL_SA_KEY")

echo "$SECRET" | helm registry login --username _json_key --password-stdin "$HELM_LOGIN_URL"
