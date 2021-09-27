#!/usr/bin/env bash

set -xeuEo pipefail

apt-get update
apt-get upgrade -y
apt-get install -y gunicorn python3-httpbin

cat > /etc/systemd/system/gunicorn.service <<EOF
[Unit]
After=network.target
After=syslog.target

[Service]
ExecStart=gunicorn -b 0.0.0.0:80 httpbin:app -k gevent
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable gunicorn.service

hostnamectl set-hostname external-vm

reboot
