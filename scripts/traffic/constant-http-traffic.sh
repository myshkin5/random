#!/usr/bin/env zsh

set -euEo pipefail

TMP_DIR=$(mktemp -d -t "constant-http-traffic")
cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  rm -rf "$TMP_DIR"
}
trap cleanup SIGINT SIGTERM ERR EXIT

mkdir -p "$TMP_DIR"

OPTS=("-n" "10000" "-c" "20")
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

    echo "$(date) $POD $( (kubectl exec -n http-client "$POD" -c http-client -- \
        /hey "${OPTS[@]}" http://http-server.http-server.svc.cluster.local:8000/get | grep responses) 2> /dev/null )"
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
  done < <(kubectl get pods -n http-client -l app.kubernetes.io/name=http-client -o json | \
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
