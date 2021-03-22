#!/usr/bin/env bash

set -xeuEo pipefail

if [[ $# != 2 ]]; then
    echo "Usage: $0 <merge file (supplied by script)> <file being edited (supplied by invoker of EDITOR)>"
    exit 1
fi

TMP=$(mktemp -t yq-merge-editor)

yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$1" "$2" > "$TMP"
mv "$TMP" "$2"
