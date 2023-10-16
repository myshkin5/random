#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

source "$DIR/version-support.sh"

TMP_FILE=$(mktemp -t "$(basename "${BASH_SOURCE[0]}.XXXXXXX")")
touch "$TMP_FILE"
trap 'rm "$TMP_FILE"' EXIT

kubectl apply -f "$DIR/ready.yaml"
kubectl apply -f ../private-resources/aspenmesh-pull-secret.yaml \
  --namespace istio-ready
if [[ $OPENSHIFT == "true" ]]; then
  kubectl apply -f "$DIR/net-attach-def.yaml" \
    --namespace istio-ready
fi

dots() {
  while [ -f "$TMP_FILE" ]; do
    echo -n .
    sleep 10
  done
}

LOAD_BALANCER=$(cat load-balancer.value)
echo "http://$LOAD_BALANCER/status/200"
set +x
date
echo "Time: 1 min 2 min 3 min 4 min 5 min 6 min 7 min"
dots &
while true; do
  STATUS=$(curl --silent \
    --output /dev/null \
    --write-out "%{http_code}\n" \
    "http://$LOAD_BALANCER/status/200" || true)
  if [[ $STATUS == 200 ]]; then
    break
  fi
  sleep 5
done
echo
date
set -x

kubectl delete namespace istio-ready
