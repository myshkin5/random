#!/usr/bin/env bash

set -xEeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [[ -f "metadata.json" || -d "auth" || -d "tls" || $(find . -name terraform.\* 2> /dev/null | wc -l) -gt 0 ]]; then
  echo "Delete cluster and cleanup ./auth, ./tls and terraform.*"
  exit 1
fi

cp template.install-config.yaml install-config.yaml
openshift-install create cluster --dir=. --log-level=info

chmod -R go-rwx auth

#oc adm policy add-scc-to-user privileged -z istio-cni -n kube-system
oc adm policy add-scc-to-group anyuid system:serviceaccounts

kubectl apply -f "$DIR/kubernetes-sigs-metrics-server-components-v0.4.1-ocp.yaml"
