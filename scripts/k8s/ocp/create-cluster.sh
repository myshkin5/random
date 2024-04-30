#!/usr/bin/env bash

set -xEeuo pipefail

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  if [ -n "${ORIG_GOOGLE_ACCOUNT:-}" ]; then
    gcloud config set account "$ORIG_GOOGLE_ACCOUNT"
  fi
}
trap cleanup SIGINT SIGTERM ERR EXIT

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [[ -f "metadata.json" || -d "auth" || -d "tls" || $(find . -name terraform.\* 2> /dev/null | wc -l) -gt 0 ]]; then
  echo "Delete cluster and cleanup ./auth, ./tls and terraform.*"
  exit 1
fi

if [[ $(grep -c "name: $NAME$" template.install-config.yaml) != 1 ]]; then
  echo "NAME env var doesn't match name in template install config"
  exit 1
fi

date

if [ -n "${OCP_INSTALLER_SA_KEY:-}" ]; then
  export GOOGLE_APPLICATION_CREDENTIALS=$PWD/ocp-sa-keyfile.json
  gcloud secrets versions access latest --secret="${OCP_INSTALLER_SA_KEY}" > "$GOOGLE_APPLICATION_CREDENTIALS"
  ORIG_GOOGLE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
  gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --verbosity=debug
else
  SECRET=$(aws secretsmanager get-secret-value \
    --secret-id openshift_passthrough_credentials | jq -r '.SecretString')
  AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.aws_access_key_id')
  AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.aws_secret_access_key')
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
fi

cp template.install-config.yaml install-config.yaml
openshift-install create cluster --dir=. --log-level=debug

chmod -R go-rwx auth

#oc adm policy add-scc-to-user privileged -z istio-cni -n kube-system
oc adm policy add-scc-to-group anyuid system:serviceaccounts

"$DIR/../../metrics-server/deploy-metrics-server.sh"
"$DIR/../../kube-prometheus/deploy-kube-prom.sh"
