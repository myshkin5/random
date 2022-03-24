#!/usr/bin/env bash

set -euEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

while true; do
  while read -r SITE; do
    POD=$(kubectl get pods -n traffic-client -l app=client -o jsonpath='{.items[0].metadata.name}')
    echo "$(date) ${SITE:0:8} $(kubectl exec -n traffic-client -c client "$POD" -- \
      curl "https://$SITE/" -vvvv --silent 2>&1 | grep "^< HTTP/2\|^< HTTP/1.1\|^\* OpenSSL")"
    sleep 1
  done < "$DIR/sites.txt"
done
