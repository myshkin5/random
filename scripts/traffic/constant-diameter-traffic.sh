#!/usr/bin/env zsh

set -euEo pipefail

TMP_DIR=$(mktemp -d -t "constant-diameter-traffic")
cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  rm -rf "$TMP_DIR"
}
trap cleanup SIGINT SIGTERM ERR EXIT

mkdir -p "$TMP_DIR"

OPTS=("-bench" "-bench_clients" "1" "-bench_msgs" "1000" "-bench_timeout" "1s")
if [ $# -gt 0 ]; then
  OPTS+=("$@")
fi

constant-traffic() {
  POD=$1

  echo "$POD started."

  while true; do
    if [[ ! -f "$TMP_DIR/$POD" ]]; then
      break
    fi

    RET_CODE=0
    OUT=$(kubectl exec -n diameter-client "$POD" -c diameter-client -- \
      diameter-client -addr diameter-server.diameter-server:3868 "${OPTS[@]}" 2>&1 | grep "messages in") || RET_CODE=$?
    echo "$POD $OUT"
    if [ "$RET_CODE" != 0 ]; then
      echo "$(DATE) $POD Non-zero return code ($RET_CODE), sleeping"
      sleep 5
    fi
  done

  echo "$POD stopped."
}

while true; do
  unset PODS
  declare -A PODS
  while read -r POD; do
    PODS[$POD]=1
    if [[ ! -f "$TMP_DIR/$POD" ]]; then
      touch "$TMP_DIR/$POD"
      echo "$POD starting..."
      constant-traffic "$POD" &
    fi
  done < <(kubectl get pods -n diameter-client -l app.kubernetes.io/name=diameter-client -o json | \
    jq -r '.items[].metadata.name')

  for F in "$TMP_DIR"/*; do
    POD=$(basename "$F")
    if [ ! "${PODS[$POD]:-}" ]; then
      echo "$POD stopping..."
      rm "$F"
    fi
  done

  sleep 5
done
