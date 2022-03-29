#!/usr/bin/env bash

set -euEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

parse-params() {
  # default values of variables set from params
  HOST_HEADER=""
  PROTOCOL=https
  USE_FQDNS=0

  while true; do
    case "${1-}" in
    -h | --host)
      HOST_HEADER="${2-}"
      shift
      ;;
    -p | --protocol)
      PROTOCOL="${2-}"
      shift
      ;;
    --use-fqdns) USE_FQDNS=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse-params "$@"

OPTS=("-vvvv" "--silent" "--output" "/dev/null")
if [ -n "$HOST_HEADER" ]; then
  OPTS+=("--header" "Host: $HOST_HEADER")
fi

while true; do
  while read -r SITE; do
    if [[ $USE_FQDNS == 1 ]]; then
      SITE+="."
    fi

    POD=$(kubectl get pods -n traffic-client -l app=client -o jsonpath='{.items[0].metadata.name}')

    CURL=$(kubectl exec -n traffic-client -c client "$POD" -- \
      curl "$PROTOCOL://$SITE/" "${OPTS[@]}" 2>&1) || true
    CONNECTED_TO=""
    REGEX="Trying (.*)\.\.\."
    if [[ "$CURL" =~ $REGEX ]]; then
      CONNECTED_TO="${BASH_REMATCH[1]}"
    fi
    RESULT=$(echo "$CURL" | grep "^< HTTP/\|^\* OpenSSL")

    printf "$(date +"%T") %-8.8s %-19.19s %s\n" "$SITE" "$CONNECTED_TO" "$RESULT"
    sleep 1
  done < "$DIR/sites.txt"
done
