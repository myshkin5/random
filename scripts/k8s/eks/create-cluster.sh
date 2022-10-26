#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-c]

Create an EKS cluster

Available options:

-h, --help       Print this help and exit
-c, --via-config Specifies the cache file path to use (defaults to most
EOF
  exit
}

setup-colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NORMAL=$(tput sgr0) RED=$(tput setaf 1) GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3) BLUE=$(tput setaf 4) CYAN=$(tput setaf 6)
  else
    NORMAL='' RED='' GREEN='' YELLOW='' BLUE='' CYAN=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse-params() {
  # default values of variables set from params
  VIA_CONFIG=0

  while true; do
    case "${1-}" in
    -h | --help) usage ;;
    -c | --via-config) VIA_CONFIG=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse-params "$@"
setup-colors

INSTANCE_TYPE=${INSTANCE_TYPE:=t3a.large}
NODE_COUNT=${NODE_COUNT:=5}
SSH_PUBLIC_KEY=${SSH_PUBLIC_KEY:="$HOME/.ssh/id_ed25519_aws_dev.pub"}
VER_OPT=""
if [ -n "${K8S_VERSION:-}" ]; then
  VER_OPT="--version=$K8S_VERSION"
fi

date

if [ "$VIA_CONFIG" == 0 ]; then
  eksctl create cluster \
    --name="$NAME" \
    $VER_OPT \
    --node-type="$INSTANCE_TYPE" \
    --nodes-min="$NODE_COUNT" \
    --nodes-max="$NODE_COUNT" \
    --ssh-access \
    --ssh-public-key="$SSH_PUBLIC_KEY" \
    --external-dns-access \
    --kubeconfig="$KUBECONFIG"
else
  eksctl create cluster -f "$DIR/cluster.yaml" \
    --kubeconfig="$KUBECONFIG"
fi

"$DIR/../../metrics-server/deploy-metrics-server.sh"

aws cloudformation describe-stacks --stack-name "eksctl-$NAME-cluster" \
  | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="VPC") | .OutputValue' > vpc-id.value

aws cloudformation describe-stacks --stack-name "eksctl-$NAME-cluster" \
  | jq -r '.Stacks[0].Outputs[] | select(.OutputKey=="SubnetsPublic") | .OutputValue' \
  | cut -d , -f 1 > public-subnet-id.value
