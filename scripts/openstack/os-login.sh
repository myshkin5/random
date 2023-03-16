#!/usr/bin/env bash

set -euEo pipefail

NORMAL=$(tput sgr0)
YELLOW=$(tput setaf 3)

if [ -z "${OS_AUTH_URL:-}" ]; then
  echo "OS_AUTH_URL not set"
  exit 1
fi

if [ -z "${OS_USER_ID:-}" ]; then
  echo "OS_USER_ID not set"
  exit 1
fi

TOKEN=$(OS_AUTH_TYPE="" OS_TOKEN="" openstack token issue --insecure --format=json)
EXP=$(echo "$TOKEN" | jq -r '.expires')
ID=$(echo "$TOKEN" | jq -r '.id')

FILE="$HOME/.oh-my-zsh/custom/openstack-token.zsh"
echo "export OS_AUTH_TYPE=v3token" > "$FILE"
echo "export OS_TOKEN=$ID" >> "$FILE"
echo "export OS_LOGIN_TOKEN_EXPIRES=$EXP" >> "$FILE"

echo "Token expires at $YELLOW$EXP$NORMAL"
echo "Start a new shell or execute the following:"
echo "  source $FILE"
