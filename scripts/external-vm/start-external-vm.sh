#!/usr/bin/env bash

set -xeuEo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

IMAGE_ID=${IMAGE_ID:=ami-03d5c68bab01f3496}
INSTANCE_TYPE=${INSTANCE_TYPE:=t3a.large}
KEY_PAIR=${KEY_PAIR:=dwayne-ed25519-key-pair}

SG_ID=$(aws ec2 create-security-group \
  --description "External VM for $NAME" \
  --group-name "$NAME-external-vm" \
  --vpc-id "$(cat vpc-id.value)" | jq -r '.GroupId')
echo "$SG_ID" > external-vm-sg.value

function add-ingress() {
  PORT=$1
  CIDR=$2
  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port "$PORT" \
    --cidr "$CIDR" | jq
}

MY_IP=$(curl -s https://api.ipify.org)
add-ingress 22 "$MY_IP/32"         # ssh to sshd

add-ingress 80 "0.0.0.0/0"         # HTTP to httpbin
add-ingress 15001 "192.168.0.0/16" # Envoy outbound
add-ingress 15006 "192.168.0.0/16" # Envoy inbound
add-ingress 15021 "192.168.0.0/16" # Health checks
add-ingress 15090 "192.168.0.0/16" # Envoy Prometheus telemetry

RUN_OUT=$(aws ec2 run-instances \
  --image-id "$IMAGE_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_PAIR" \
  --subnet-id "$(cat public-subnet-id.value)" \
  --security-group-ids "$SG_ID" \
  --user-data "file://$DIR/external-vm-startup.sh")
echo "$RUN_OUT"
echo "$RUN_OUT" | jq -r '.Instances[0].InstanceId' > external-vm-id.value
PRIVATE_IP=$(echo "$RUN_OUT" | jq -r '.Instances[0].PrivateIpAddress')
echo "$PRIVATE_IP" > external-vm-private-ip.value

aws ec2 wait instance-running --instance-ids "$(cat external-vm-id.value)" | jq
PUBLIC_IP=$(aws ec2 describe-instances \
  --filters "Name=instance-id,Values=$(cat external-vm-id.value)" | \
  jq -r ".Reservations[0].Instances[0].PublicIpAddress")
echo "$PUBLIC_IP" > external-vm-public-ip.value

while true; do
  DEV_ZONE=$(aws route53 list-hosted-zones-by-name --dns-name dev.twistio.io. | \
    jq '.HostedZones[] | select(.Name == "dev.twistio.io.") | .Id' -r | \
    cut -d/ -f 3) && break
done

aws route53 change-resource-record-sets \
  --hosted-zone-id "$DEV_ZONE" \
  --change-batch '{
    "Comment": "Creating a record set for the external VM",
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "external-vm.'"$NAME"'.dev.twistio.io",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            { "Value": "'"$PRIVATE_IP"'" }
          ]
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "pub-external-vm.'"$NAME"'.dev.twistio.io",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            { "Value": "'"$PUBLIC_IP"'" }
          ]
        }
      }
    ]
  }' | jq
