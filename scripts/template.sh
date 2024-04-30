#!/usr/bin/env bash

set -euEo pipefail

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}
trap cleanup SIGINT SIGTERM ERR EXIT

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
}

setup-colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NORMAL=$(tput sgr0) RED=$(tput setaf 1) GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3) BLUE=$(tput setaf 4) CYAN=$(tput setaf 6)
    echo "$NORMAL"
  else
    NORMAL='' RED='' GREEN='' YELLOW='' BLUE='' CYAN=''
  fi
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
  FLAG=0
  PARAM=''
  ARGS=()

  while [[ $# -gt 0 ]]; do
    case "${1-}" in
    -h | --help)     usage; exit 0 ;;
    -v | --verbose)  set -x ;;
    --no-color)      NO_COLOR=1 ;;
    -f | --flag)     FLAG=1 ;;
    -p | --param)    PARAM="${2-}"; shift ;;
    -?*)             usage-err "Unknown option: $1" ;;
    *)               ARGS+=("${1-}") ;;
    esac
    shift
  done

  # check required params and arguments
  [[ -z "${PARAM-}" ]] && usage-err "Missing required parameter: param"
  [[ ${#ARGS[@]} -eq 0 ]] && usage-err "Missing script arguments"

  return 0
}

parse-params "$@"
setup-colors

# script logic here

msg "${RED}Read parameters:${NORMAL}"
msg "- flag: ${FLAG}"
msg "- param: ${PARAM}"
msg "- arguments: ${ARGS[*]-}"
