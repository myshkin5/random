#!/usr/bin/env bash

set -xEeuo pipefail

if [[ ${DNS_ZONE:-} == "" ]]; then
  echo "DNS_ZONE is undefined"
  exit 1
fi

SECRET=$(aws secretsmanager get-secret-value \
  --secret-id openshift_passthrough_credentials | jq -r '.SecretString')
AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.aws_access_key_id')
AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.aws_secret_access_key')
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

openshift-install destroy cluster --dir=. --log-level=info || true

aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME*" | jq

while true; do
  ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DNS_ZONE" | \
    jq ".HostedZones[] | select(.Name == \"$DNS_ZONE\") | .Id" -r | \
    cut -d/ -f 3) && break
done
while true; do
  aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[?Name == 'api.$NAME.$DNS_ZONE']" | jq && break
done

# REC="$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID"
#   --query "ResourceRecordSets[?Name == \'api.$NAME.$DNS_ZONE\']" | \
#   jq --compact-output '.[0]')"
# aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" \
#  --change-batch '{ "Changes": [ { "Action": "DELETE", "ResourceRecordSet": '$REC'} ] }'

while true; do
  aws route53 list-hosted-zones-by-name --dns-name "$DNS_ZONE" | \
    jq ".HostedZones[] | select(.Name == \"$NAME.$DNS_ZONE\")" && break
done
