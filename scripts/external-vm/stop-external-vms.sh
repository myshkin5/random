#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

INSTANCE_COUNT=${INSTANCE_COUNT:=1}

kubectl delete -f "$DIR/external-vm-workloadgroup.yaml" || true
kubectl delete -f "$DIR/external-vm.yaml" || true
kubectl delete ns external || true

while true; do
  DEV_ZONE=$(aws route53 list-hosted-zones-by-name --dns-name dev.twistio.io. | \
    jq '.HostedZones[] | select(.Name == "dev.twistio.io.") | .Id' -r | \
    cut -d/ -f 3) && break
done

INST_IDS=()
for (( INST_ITER=0; INST_ITER<INSTANCE_COUNT; INST_ITER++ )); do
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$DEV_ZONE" \
    --change-batch '{
      "Comment": "Deleting the record set for the external VM",
      "Changes": [
        {
          "Action": "DELETE",
          "ResourceRecordSet": {
            "Name": "external-vm-'"$INST_ITER"'.'"$NAME"'.dev.twistio.io",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [
              { "Value": "'"$(cat "external-vm-private-ip-$INST_ITER.value")"'" }
            ]
          }
        },
        {
          "Action": "DELETE",
          "ResourceRecordSet": {
            "Name": "pub-external-vm-'"$INST_ITER"'.'"$NAME"'.dev.twistio.io",
            "Type": "A",
            "TTL": 300,
            "ResourceRecords": [
              { "Value": "'"$(cat "external-vm-public-ip-$INST_ITER.value")"'" }
            ]
          }
        }
      ]
    }' \
    --no-cli-pager || true | jq

  INST_IDS+=("$(cat "external-vm-id-$INST_ITER.value")")
done

aws ec2 terminate-instances --instance-ids "${INST_IDS[@]}" | jq

aws ec2 wait instance-terminated --instance-ids "${INST_IDS[@]}" | jq

aws ec2 delete-security-group --group-id "$(cat external-vm-sg.value)" || true
