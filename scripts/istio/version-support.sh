#!/usr/bin/env bash

set -xeuEo pipefail

VER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

if [[ ${RELEASE_PATH:-} == "" ]]; then
  echo "RELEASE_PATH is undefined"
  exit 1
fi

if [ ! -d "$RELEASE_PATH" ]; then
  echo "RELEASE_PATH ($RELEASE_PATH) is not found"
  exit 1
fi

if [[ ${OVERRIDES:-} == "" ]]; then
  OVERRIDES=${DEFAULT_OVERRIDES:-}
  echo "Defaulting overrides to $OVERRIDES"
fi

VALUES_OPTS=("--values=$OVERRIDES")
if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  OPENSHIFT=true
  VALUES_OPTS+=("--values=$VER_DIR/overrides/cni.yaml")
else
  export OPENSHIFT=false
fi

HUB_AND_TAG=false
VER=$(grep -e "^version:" "$RELEASE_PATH/manifests/charts/base/Chart.yaml" | awk '{ print $2 }')
ISTIO_MINOR_VERSION=$(echo "$VER" | cut -d \. -f "1-2")
ISTIO_PATCH_VERSION=$(echo "$VER" | cut -d \. -f "1-3" | cut -d - -f 1)
export ISTIO_MINOR_VERSION ISTIO_PATCH_VERSION
export AM_RELEASE=false
if [[ $VER =~ .*-am.* ]]; then
  export AM_RELEASE=true
fi
case $ISTIO_MINOR_VERSION in
  1.11)
    if [ $AM_RELEASE == "true" ]; then
      export CRD_COUNT=15
    else
      export CRD_COUNT=13
    fi
    ;;
  1.14)
    export CRD_COUNT=15
    ;;
  1.18)
    export CRD_COUNT=15
    ;;
  *)
    echo "Unknown minor version"
    exit 1
    ;;
esac

if [[ $HUB_AND_TAG == true ]]; then
  VALUES_OPTS+=("--set=global.hub=docker.io/istio")
  VALUES_OPTS+=("--set=global.tag=$VER")
else
  if [[ "$RELEASE_PATH" =~ -(PR|pr) ]]; then
    VALUES_OPTS+=("--set=global.hub=quay.io/aspenmesh/releases-pr")
    VALUES_OPTS+=("--set=global.publicImagesHub=quay.io/aspenmesh/am-istio-pr")
  fi
fi

export VALUES_OPTS
