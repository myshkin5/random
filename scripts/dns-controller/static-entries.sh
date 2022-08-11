#!/usr/bin/env bash

set -euEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

parse-params() {
  # default values of variables set from params
  DELETE=0

  while true; do
    case "${1-}" in
    --delete) DELETE=1 ;;
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
    kubectl delete dnsstaticentry "$NAME" -n istio-system || true
    continue
  fi

  FILE=$(mktemp -t dns-hack-static-entry)
  sed \
    -e "s/~~NAME~~/$NAME/g" \
    -e "s/~~SITE~~/$SITE/g" \
    "$DIR/static-entry.yaml" > "$FILE"

  kubectl apply -f "$FILE"

  rm "$FILE"
done < "$DIR/sites.txt"
