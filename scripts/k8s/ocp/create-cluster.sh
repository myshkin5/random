#!/usr/bin/env bash

set -xEeuo pipefail

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

SECRET=$(aws secretsmanager get-secret-value \
  --secret-id openshift_passthrough_credentials | jq -r '.SecretString')
AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.aws_access_key_id')
AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.aws_secret_access_key')
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

cp template.install-config.yaml install-config.yaml
openshift-install create cluster --dir=. --log-level=info

chmod -R go-rwx auth

#oc adm policy add-scc-to-user privileged -z istio-cni -n kube-system
oc adm policy add-scc-to-group anyuid system:serviceaccounts

"$DIR/../../metrics-server/deploy-metrics-server.sh"
"$DIR/../../kube-prometheus/deploy-kube-prom.sh"
