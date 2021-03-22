#!/usr/bin/env bash

set -xeuEo pipefail

kops delete cluster "$NAME" --yes || true
