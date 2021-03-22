#!/usr/bin/env bash

set -xEeuo pipefail

openshift-install destroy cluster --dir=. --log-level=info || true

aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME*" | jq

DEV_ZONE=$(aws route53 list-hosted-zones-by-name --dns-name dev.twistio.io. | \
  jq '.HostedZones[] | select(.Name == "dev.twistio.io.") | .Id' -r | \
  cut -d/ -f 3)
aws route53 list-resource-record-sets --hosted-zone-id "$DEV_ZONE" | grep dwayne || true

aws route53 list-hosted-zones-by-name --dns-name dev.twistio.io. | \
  jq ".HostedZones[] | select(.Name == \"$NAME.dev.twistio.io.\")"
