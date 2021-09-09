#!/usr/bin/env bash

set -euEo pipefail

aws sso login

# Forces an update to the metadata
aws sts get-caller-identity > /dev/null

echo "Successfully logged in with $(sso-minutes-remaining.sh --human) minutes remaining"
