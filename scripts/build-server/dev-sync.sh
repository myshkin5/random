#!/usr/bin/env bash

set -xeEo pipefail

if [ -z "$BUILD_SERVER_SSH_KEY_FILE" ]; then
  >&2 echo "BUILD_SERVER_SSH_KEY_FILE must be defined"
  exit 1
fi

if [ -z "$BUILD_SERVER" ]; then
  >&2 echo "BUILD_SERVER must be defined"
  exit 1
fi

if [ -z "$BUILD_USER" ]; then
  >&2 echo "BUILD_USER must be defined"
  exit 1
fi

if [[ $PWD != $HOME* ]]; then
  >&2 echo "Current working directory must be in home directory"
  exit 1
fi

REL_PATH=${PWD:(( ${#HOME}+1 ))}

ssh -i "$BUILD_SERVER_SSH_KEY_FILE" "$BUILD_USER@$BUILD_SERVER" -- mkdir -p "$REL_PATH"

RSYNC_OPTS=""
if [ -f .gitignore ]; then
  RSYNC_OPTS="--exclude-from=.gitignore"
fi

# "$@" is provided because on occasion you should pass --delete to rsync to
# clean things up
rsync -av --rsh="ssh -i \"$BUILD_SERVER_SSH_KEY_FILE\"" $RSYNC_OPTS "$@" \
  . "$BUILD_USER@$BUILD_SERVER:$REL_PATH"
