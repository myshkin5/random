#!/usr/bin/env bash

set -euEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

parse-params() {
  # default values of variables set from params
  RESOLUTION=DNS
  DELETE=0

  while true; do
    case "${1-}" in
    --delete) DELETE=1 ;;
    -r | --resolution)
      RESOLUTION="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse-params "$@"

while read -r SITE; do
  NAME="dns-hack-$(echo "$SITE" | cut -d\. -f 2)"
  if [[ $DELETE == 1 ]]; then
    kubectl delete serviceentry "$NAME" -n istio-system || true
    continue
  fi

  FILE=$(mktemp -t dns-hack-service-entry)
  sed \
    -e "s/~~NAME~~/$NAME/g" \
    -e "s/~~SITE~~/$SITE/g" \
    -e "s/~~RESOLUTION~~/$RESOLUTION/g" \
    "$DIR/dns-hack-service-entry.yaml" > "$FILE"

  if [ "$RESOLUTION" == "STATIC" ]; then
    echo "  endpoints:" >> "$FILE"
    dig +short "$SITE" | grep -v "\.$" | while read -r IP; do
      echo "  - address: $IP" >> "$FILE"
    done
  fi

  kubectl apply -f "$FILE"

  rm "$FILE"
done < "$DIR/dns-hack-sites.txt"
