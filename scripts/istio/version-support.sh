#!/usr/bin/env bash

set -xeuEo pipefail

if [[ ${RELEASE_PATH:-} == "" ]]; then
  echo "RELEASE_PATH is undefined"
  exit 1
fi

if [ ! -d "$RELEASE_PATH" ]; then
  echo "RELEASE_PATH ($RELEASE_PATH) is not found"
  exit 1
fi

if (( $(kubectl get ns | grep -c openshift) > 0 )); then
  OPENSHIFT=true
else
  OPENSHIFT=false
fi
export OPENSHIFT

CHARTS_PATH=$RELEASE_PATH
if [[ -d "$CHARTS_PATH/manifests/charts" ]]; then
  CHARTS_PATH+=/manifests/charts
fi

VER=$(grep -e "^version:" "$CHARTS_PATH/base/Chart.yaml" | awk '{ print $2 }')
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
