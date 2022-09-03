#!/usr/bin/env bash

while true; do
  POD=$(kubectl get pods -n traffic-client -l app=client -o jsonpath='{.items[0].metadata.name}' 2> /dev/null)

  SPACE=" "
  kubectl exec "$POD" -n traffic-client -- ls hey > /dev/null 2>&1
  if [[ $? != 0 ]]; then
    kubectl cp ~/workspace/hey_linux_amd64 -c client "traffic-client/$POD:hey" > /dev/null 2>&1
    kubectl exec -n traffic-client -c client "$POD" -- chmod +x /hey > /dev/null 2>&1
    SPACE="^"
  fi

  echo "$(date)$SPACE$( (kubectl exec -n traffic-client "$POD" -c client -- \
      ./hey -n 10000 -c 1000 http://server.traffic-server.svc.cluster.local:8000/get | grep responses) 2> /dev/null )"
done
