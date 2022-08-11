#!/usr/bin/env bash

set -euEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

parse-params() {
  # default values of variables set from params
  HOST_HEADER_OVERRIDE=""
  PRINT_COMMAND=0
  PROTOCOL=https
  SERVER_OVERRIDE=""
  USE_FQDNS=0
  USE_SNI=0

  while true; do
    case "${1-}" in
    -h | --host-header-override)
      HOST_HEADER_OVERRIDE="${2-}"
      shift
      ;;
    --print-command) PRINT_COMMAND=1 ;;
    -p | --protocol)
      PROTOCOL="${2-}"
      shift
      ;;
    -s | --server-override)
      SERVER_OVERRIDE="${2-}"
      shift
      ;;
    --use-fqdns) USE_FQDNS=1 ;;
    --use-sni) USE_SNI=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse-params "$@"

OPTS=("-vvvv" "--silent" "--output" "/dev/null")
if [ -n "$HOST_HEADER_OVERRIDE" ]; then
  OPTS+=("--header" "Host: $HOST_HEADER_OVERRIDE")
fi

case "$PROTOCOL" in
http) PORT=80 ;;
https) PORT=443 ;;
?*) die "Unknown protocol $PROTOCOL"
esac

while true; do
  while read -r SITE; do
    LOCAL_OPTS=("${OPTS[@]}")
    if [ -z "$HOST_HEADER_OVERRIDE" ]; then
      LOCAL_OPTS+=("--header" "Host: $SITE")
    fi
    LOCAL_SITE=$SITE
    if [ -n "$SERVER_OVERRIDE" ]; then
      if [[ $USE_SNI == 1 ]]; then
        LOCAL_OPTS+=("--resolve" "$LOCAL_SITE:$PORT:$SERVER_OVERRIDE")
      else
        LOCAL_SITE=$SERVER_OVERRIDE
      fi
    fi
    if [[ $USE_FQDNS == 1 ]]; then
      LOCAL_SITE+="."
    fi

    POD=$(kubectl get pods -n traffic-client -l app=client -o jsonpath='{.items[0].metadata.name}')

    CURL=$(kubectl exec -n traffic-client -c client "$POD" -- \
      curl "$PROTOCOL://$LOCAL_SITE/" "${LOCAL_OPTS[@]}" 2>&1) || true
    CONNECTED_TO=""
    REGEX="Trying (.*)\.\.\."
    if [[ "$CURL" =~ $REGEX ]]; then
      CONNECTED_TO="${BASH_REMATCH[1]}"
    fi
    RESULT=$(echo "$CURL" | grep "^< HTTP/\|^\* OpenSSL") || true

    if [[ $PRINT_COMMAND == 1 ]]; then
      printf "$(date +"%T") %-19.19s curl $PROTOCOL://$LOCAL_SITE/ ${LOCAL_OPTS[*]} %s\n" "$CONNECTED_TO" "$RESULT"
    else
      printf "$(date +"%T") %-8.8s %-19.19s %s\n" "$SITE" "$CONNECTED_TO" "$RESULT"
    fi
    sleep 1
  done < "$DIR/sites.txt"
done
