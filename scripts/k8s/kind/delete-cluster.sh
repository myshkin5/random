#!/usr/bin/env bash

set -xEeuo pipefail

kind delete cluster --name "$NAME"
