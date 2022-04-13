#!/usr/bin/env bash

set -euEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

parse-params() {
  # default values of variables set from params
  DELETE=0
  FIRST_ENTRY_ONLY=0
  LOOKUP_STATIC=0
  RESOLUTION=""
  USE_FQDNS=0

  while true; do
    case "${1-}" in
    --delete) DELETE=1 ;;
    -f | --first-entry-only) FIRST_ENTRY_ONLY=1 ;;
    --lookup-static) LOOKUP_STATIC=1 ;;
    -r | --resolution)
      RESOLUTION="${2-}"
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

while read -r SITE; do
  NAME="dns-hack-$(echo "$SITE" | cut -d\. -f 1)"
  if [[ $DELETE == 1 ]]; then
    kubectl delete serviceentry "$NAME" -n istio-system || true
    continue
  fi

  if [[ $USE_FQDNS == 1 ]]; then
    SITE+="."
  fi

  FILE=$(mktemp -t dns-hack-service-entry)
  sed \
    -e "s/~~NAME~~/$NAME/g" \
    -e "s/~~SITE~~/$SITE/g" \
    -e "s/~~RESOLUTION~~/$RESOLUTION/g" \
    "$DIR/service-entry.yaml" > "$FILE"

  if [ -n "$RESOLUTION" ]; then
    echo "  resolution: $RESOLUTION" >> "$FILE"

    if [ "$RESOLUTION" == "STATIC" ]; then
      if [ "$LOOKUP_STATIC" == 0 ]; then
        echo "  endpoints: []" >> "$FILE"
      else
        echo "  endpoints:" >> "$FILE"
        dig +short "$SITE" | grep -v "\.$" | while read -r IP; do
          echo "  - address: $IP" >> "$FILE"
          if [ "$FIRST_ENTRY_ONLY" == 1 ]; then
            break
          fi
        done
      fi
    fi
  fi

  kubectl apply -f "$FILE"

  rm "$FILE"
done < "$DIR/sites.txt"
