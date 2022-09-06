#!/usr/bin/env bash

set -xEeuo pipefail

REPLICAS=$(yq ".compute[] | select(.name == \"worker\") | .replicas" \
  template.install-config.yaml)
MACHINE_SETS=$(oc get machinesets -n openshift-machine-api -o name)
MS_COUNT=$(echo "$MACHINE_SETS" | wc -l)
(( R_PER_MS = REPLICAS / MS_COUNT ))
if (( R_PER_MS * MS_COUNT < REPLICAS )); then
  (( R_PER_MS++ ))
fi

COUNT=0
for MACHINE_SET in $MACHINE_SETS; do
  (( COUNT += R_PER_MS ))
  if (( COUNT > REPLICAS )); then
    (( R_PER_MS -= COUNT - REPLICAS ))
  fi
  oc scale --replicas="$R_PER_MS" "$MACHINE_SET" --namespace openshift-machine-api
done

while true; do
  if (( $(oc wait --for=condition=Ready node \
      --selector=node-role.kubernetes.io/worker | wc -l) == "$REPLICAS" )); then
    break
  fi
  sleep 5
done

oc get machinesets -n openshift-machine-api
