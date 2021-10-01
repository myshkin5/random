#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

kubectl delete -f "$DIR/external-vm-workloadgroup.yaml" || true
kubectl delete -f "$DIR/external-vm.yaml" || true

while true; do
  DEV_ZONE=$(aws route53 list-hosted-zones-by-name --dns-name dev.twistio.io. | \
    jq '.HostedZones[] | select(.Name == "dev.twistio.io.") | .Id' -r | \
    cut -d/ -f 3) && break
done

aws route53 change-resource-record-sets \
  --hosted-zone-id "$DEV_ZONE" \
  --change-batch '{
    "Comment": "Deleting the record set for the external VM",
    "Changes": [
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "external-vm.'"$NAME"'.dev.twistio.io",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            { "Value": "'"$(cat external-vm-private-ip.value)"'" }
          ]
        }
      },
      {
        "Action": "DELETE",
        "ResourceRecordSet": {
          "Name": "pub-external-vm.'"$NAME"'.dev.twistio.io",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            { "Value": "'"$(cat external-vm-public-ip.value)"'" }
          ]
        }
      }
    ]
  }' | jq || true

aws ec2 terminate-instances --instance-ids "$(cat external-vm-id.value)" | jq

aws ec2 wait instance-terminated --instance-ids "$(cat external-vm-id.value)" | jq

aws ec2 delete-security-group --group-id "$(cat external-vm-sg.value)" || true
