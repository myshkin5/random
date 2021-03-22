#!/usr/bin/env bash

set -xeuEo pipefail

eksctl delete cluster --name "$NAME" --wait || true
