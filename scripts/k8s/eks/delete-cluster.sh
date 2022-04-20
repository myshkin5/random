#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-c]

Delete an EKS cluster

Available options:

-h, --help       Print this help and exit
-c, --via-config Specifies the cache file path to use (defaults to most
EOF
  exit
}

setup-colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NORMAL=$(tput sgr0) RED=$(tput setaf 1) GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3) BLUE=$(tput setaf 4) CYAN=$(tput setaf 6)
  else
    NORMAL='' RED='' GREEN='' YELLOW='' BLUE='' CYAN=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse-params() {
  # default values of variables set from params
  VIA_CONFIG=0

  while true; do
    case "${1-}" in
    -h | --help) usage ;;
    -c | --via-config) VIA_CONFIG=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse-params "$@"
setup-colors

if [ "$VIA_CONFIG" == 0 ]; then
  eksctl delete cluster --name "$NAME" --wait || true
else
  eksctl delete cluster -f "$DIR/cluster.yaml" --wait || true
fi
