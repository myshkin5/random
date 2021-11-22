#!/usr/bin/env bash

set -euEo pipefail

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [--[no-]human]
                                [-a minutes] [-r minutes] [-w minutes]
                                [-c cache-file-path]

Displays minutes remaining for an SSO session.

Available options:

-h, --help          Print this help and exit
-v, --verbose       Print script debug info
-c, --cache-file    Specifies the cache file path to use (defaults to most
                    recently modified file in \$HOME/.aws/cli/cache)
    --human         Output in human readable form (1:30 instead of 1.5)
    --no-human      Output floating point minutes (default)
-a, --add           Add specified minutes (default: 0)
-r, --red-threshold Displays red output when threshold is crossed (default: 0)
-w, --watch         Watch the SSO session indefinitely with a sleep for the
                    specified minutes (default: don't watch)
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
  HUMAN=0
  ADD_MINUTES=0
  RED_THRESHOLD=0
  WATCH_MINUTES=0
  CLI_CACHE=""

  while true; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -c | --cache-file)
      CLI_CACHE="${2-}"
      shift
      ;;
    --human) HUMAN=1 ;;
    --no-human) HUMAN=0 ;;
    -a | --add)
      ADD_MINUTES="${2-}"
      shift
      ;;
    -r | --red-threshold)
      RED_THRESHOLD="${2-}"
      shift
      ;;
    -w | --watch)
      WATCH_MINUTES="${2-}"
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
setup-colors

if [ -z "$CLI_CACHE" ]; then
  CLI_CACHE_DIR=$HOME/.aws/cli/cache
  if [ ! -d "$CLI_CACHE_DIR" ]; then
    echo -1
    exit
  fi

  CLI_CACHE=$(gfind "$CLI_CACHE_DIR" -type f -printf '%T@ %p\n' | sort | cut -d ' ' -f 2- | tail -1)
fi

function check() {
  MINUTES_F=$(jq -r "((.Credentials.Expiration | fromdate) - now)/60" "$CLI_CACHE")
  MINUTES_F=$(echo "$MINUTES_F + $ADD_MINUTES" | bc | awk '{printf "%f", $0}')
  PRE=""
  if (( $(echo "$MINUTES_F < $RED_THRESHOLD" | bc -l) )); then
    PRE=$RED
  fi

  if [ "$HUMAN" == 1 ]; then
    MINUTES_I=${MINUTES_F%.*}
    SECONDS_I=$(echo "($MINUTES_F - $MINUTES_I) * 60" | bc)
    SECONDS_I=$(echo "($MINUTES_F - $MINUTES_I) * 60" | bc)
    SECONDS_I=${SECONDS_I#-}
    printf "$PRE%.0f:%02.0f$NORMAL\n" "$MINUTES_I" "$SECONDS_I"
  else
    echo -e "$PRE$MINUTES_F$NORMAL"
  fi
}

if [[ "$WATCH_MINUTES" == "0" ]]; then
  check
else
  (( SECS=WATCH_MINUTES*60 ))
  while true; do
    echo "$(date) $(check)"
    sleep "$SECS"
  done
fi
