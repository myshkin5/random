#!/bin/bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

kubectl apply -f "$DIR/traffic-generator.yaml"

if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" \
    --namespace packet-inspector-traffic-server
  kubectl apply -f "$DIR/../istio/net-attach-def.yaml" \
    --namespace packet-inspector-traffic-client
fi

POD=""
while [ "$POD" == "" ]; do
  POD=$(kubectl get pod -n packet-inspector-traffic-client \
    -l app=client \
    -o jsonpath='{.items[0].metadata.name}' || true)
  sleep 1
done

while true; do
  ORIGIN=$(kubectl exec -n packet-inspector-traffic-client -c client "$POD" \
    -- curl --silent http://server.packet-inspector-traffic-server.svc.cluster.local:8000/get | jq -r ".origin") || true
  if [[ "$ORIGIN" == "127.0.0.1" ]]; then
    break
  fi
  sleep 5
done

kubectl cp ~/workspace/hey_linux_amd64 -c client \
  "packet-inspector-traffic-client/$POD:hey"
kubectl exec -n packet-inspector-traffic-client -c client "$POD" \
  -- chmod +x /hey
kubectl exec -n packet-inspector-traffic-client -c client "$POD" \
  -- ./hey -n 1000 -q 10 -c 5 http://server.packet-inspector-traffic-server.svc.cluster.local:8000/get
