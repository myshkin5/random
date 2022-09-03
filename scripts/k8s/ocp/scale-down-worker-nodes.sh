#!/usr/bin/env bash

set -xEeuo pipefail

for MACHINE_SET in $(oc get machinesets -n openshift-machine-api -o name); do
  oc scale --replicas=0 "$MACHINE_SET" --namespace openshift-machine-api
done

for NODE_RES in $(oc get nodes --selector=node-role.kubernetes.io/worker -o name); do
  NODE=${NODE_RES#*/}
  oc get pods --all-namespaces \
      -o jsonpath='{range .items[*]}{@.metadata.name}{" "}{@.metadata.namespace}{"\n"}{end}' \
      --field-selector=spec.nodeName="$NODE" | while read -r POD NS; do
    # || true because occasionally the pod will already be gone
    oc delete pod --namespace "$NS" "$POD" || true
  done
done

while true; do
  if (( $(oc get nodes --selector=node-role.kubernetes.io/worker -o name | wc -l) == 0 )); then
    break
  fi
done

oc get machinesets -n openshift-machine-api
