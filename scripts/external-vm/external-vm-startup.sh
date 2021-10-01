#!/usr/bin/env bash

set -xeuEo pipefail

apt-get update
apt-get upgrade -y
apt-get install -y gunicorn python3-httpbin

patch /usr/lib/python3/dist-packages/httpbin/core.py <<EOF
--- /usr/lib/python3/dist-packages/httpbin/core.py	2021-10-01 16:33:33.879391022 +0000
+++ core.py	2021-10-01 16:33:08.352639364 +0000
@@ -14,6 +14,7 @@
 import time
 import uuid
 import argparse
+import socket

 from flask import Flask, Response, request, render_template, redirect, jsonify as flask_jsonify, make_response, url_for
 from werkzeug.datastructures import WWWAuthenticate, MultiDict
@@ -131,6 +132,14 @@
     return jsonify(origin=request.headers.get('X-Forwarded-For', request.remote_addr))


+@app.route('/host')
+def view_host():
+    """Returns host info."""
+
+    hostname = socket.gethostname()
+    return jsonify(hostname=hostname, host_ip=socket.gethostbyname(hostname))
+
+
 @app.route('/headers')
 def view_headers():
     """Returns HTTP HEADERS."""
EOF

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

reboot
