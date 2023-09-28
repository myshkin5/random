#!/usr/bin/env bash

set -euEo pipefail

WORK_DIR=$(mktemp -d -t "$(basename "${BASH_SOURCE[0]}.XXXXXXX")")
cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  rm -rf "$WORK_DIR"
}
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-o OS] [-a ARCHITECTURE] [blob1] [blob2...]

Downloads one or more blobs.

Available options:

-h, --help          Print this help and exit
-v, --verbose       Print script debug info
-o, --os            Only keep files with the specified operating system
-a, --architecture  Only keep files with the specified architecture
EOF
}

msg() {
  echo >&2 -e "${1-}"
}

usage-err() {
  msg "$1"
  usage
  exit 2
}

parse-params() {
  # default values of variables set from params
  BLOBS=()
  MATCH_OS=""
  MATCH_ARCH=""

  while [[ $# -gt 0 ]]; do
    case "${1-}" in
    -h | --help)          usage; exit 0 ;;
    -v | --verbose)       set -x ;;
    -o | --os)            MATCH_OS="${2-}"; shift ;;
    -a | --architecture)  MATCH_ARCH="${2-}"; shift ;;
    -?*)                  usage-err "Unknown option: $1" ;;
    *)                    BLOBS+=("${1-}") ;;
    esac
    shift
  done

  # check required params and arguments
  [[ ${#BLOBS[@]} -eq 0 ]] && usage-err "Specify at least one blob to download"

  return 0
}

parse-params "$@"

extension() {
  case $1 in
  application/x-gzip) echo "tar.gz" ;;
  application/zip)    echo "zip" ;;
  esac
}

for (( n=0; n<${#BLOBS[@]}; n++ )); do
  mkdir "$WORK_DIR/$n"
  cosign save --dir "$WORK_DIR/$n" "${BLOBS[$n]}"
  FILE=$(basename "$(echo "${BLOBS[$n]}" | cut -d: -f1)")
  VERSION=$(echo "${BLOBS[$n]}" | cut -d: -f2)
  INDEX_SHA=$(jq --raw-output '.manifests[] |
      select(.mediaType == "application/vnd.oci.image.index.v1+json") |
      .digest' \
    "$WORK_DIR/$n/index.json" | cut -d: -f2)
  while read -r SUB; do
    META_SHA=$(jq --null-input --raw-output '$in.digest' --argjson in "$SUB" | cut -d: -f2)

    ARCH=$(jq --null-input --raw-output '$in.platform.architecture' --argjson in "$SUB")
    if [[ -n $MATCH_ARCH && $ARCH != "$MATCH_ARCH" ]]; then
      continue
    fi

    OS=$(jq --null-input --raw-output '$in.platform.os' --argjson in "$SUB")
    if [[ -n $MATCH_OS && $OS != "$MATCH_OS" ]]; then
      continue
    fi

    MEDIA=$(jq --raw-output '.layers[0].mediaType' "$WORK_DIR/$n/blobs/sha256/$META_SHA")
    SHA=$(jq --raw-output '.layers[0].digest' "$WORK_DIR/$n/blobs/sha256/$META_SHA" | cut -d: -f2)
    mv "$WORK_DIR/$n/blobs/sha256/$SHA" "$FILE-$VERSION-$OS-$ARCH.$(extension "$MEDIA")"
  done < <(jq --compact-output '.manifests[]' "$WORK_DIR/$n/blobs/sha256/$INDEX_SHA")
done
