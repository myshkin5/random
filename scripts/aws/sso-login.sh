#!/usr/bin/env bash

set -euEo pipefail

if [ -z "${AWS_PROFILE:-}" ]; then
  echo "AWS_PROFILE not set"
  exit 1
fi

aws sso login

echo "Successfully logged in with $(sso-minutes-remaining.sh --human) minutes remaining"
