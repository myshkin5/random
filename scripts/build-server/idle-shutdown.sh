#!/usr/bin/env bash

set -eEou pipefail

is-active() {
  RET_CODE=0
  pgrep -u dschultz -f ssh > /dev/null || RET_CODE=$?
  if [[ $RET_CODE == 0 ]]; then
    echo 1
    return
  fi

  echo 0
}

SCHED_SHUTDOWN=$(busctl get-property \
  org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager ScheduledShutdown | awk "{print \$3}")
if [[ $SCHED_SHUTDOWN == 0 ]]; then
  if [[ $(is-active) == 0 ]]; then
    echo "$(date) Shutting down in 30 minutes..."
    sudo shutdown -h 30
    exit 0
  fi
  echo "$(date) Still active"
else
  if [[ $(is-active) != 0 ]]; then
    echo "$(date) Cancelling shutdown..."
    sudo shutdown -c
    exit 0
  fi
  echo "$(date) Still shutting down"
fi
