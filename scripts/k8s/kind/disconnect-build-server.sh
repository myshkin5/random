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

PID=$(pgrep -l -f ssh | \
  grep "$BUILD_USER@$BUILD_SERVER" | grep 443 | grep -v sudo | \
  awk '{ print $1 }' || true)
if [ -n "$PID" ]; then
  sudo kill "$PID"
fi
