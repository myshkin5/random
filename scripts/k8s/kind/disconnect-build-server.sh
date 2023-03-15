#!/usr/bin/env bash

set -xeuEo pipefail

if [ -z "$BUILD_SERVER" ]; then
  >&2 echo "BUILD_SERVER must be defined"
  exit 1
fi

if [ -z "$BUILD_USER" ]; then
  >&2 echo "BUILD_USER must be defined"
  exit 1
fi

# shellcheck disable=SC2009 # pgrep can't filter other ssh commands out
PID=$(ps auxwww | \
  grep ssh | grep "$BUILD_USER@$BUILD_SERVER" | grep 443 | grep -v sudo | \
  awk '{ print $2 }')
if [ -n "$PID" ]; then
  sudo kill "$PID"
fi
