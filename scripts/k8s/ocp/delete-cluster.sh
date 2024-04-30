#!/usr/bin/env bash

set -xEeuo pipefail

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  if [ -n "${ORIG_GOOGLE_ACCOUNT:-}" ]; then
    gcloud config set account "$ORIG_GOOGLE_ACCOUNT"
  fi
}
trap cleanup SIGINT SIGTERM ERR EXIT

if [ -n "${OCP_INSTALLER_SA_KEY:-}" ]; then
  export GOOGLE_APPLICATION_CREDENTIALS=$PWD/ocp-sa-keyfile.json
  gcloud secrets versions access latest --secret="${OCP_INSTALLER_SA_KEY}" > "$GOOGLE_APPLICATION_CREDENTIALS"
  ORIG_GOOGLE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
  gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --verbosity=debug
else
  SECRET=$(aws secretsmanager get-secret-value \
    --secret-id openshift_passthrough_credentials | jq -r '.SecretString')
  AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.aws_access_key_id')
  AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.aws_secret_access_key')
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
fi

openshift-install destroy cluster --dir=. --log-level=debug || true

if [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
  exit
fi

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
