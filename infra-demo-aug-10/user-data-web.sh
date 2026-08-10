#!/bin/bash
set -euxo pipefail
dnf install -y nginx
cat >/usr/share/nginx/html/index.html <<HTML
<html><body><h1>infra-demo-aug-10 web tier</h1><p>Private app endpoint: ${app_url}</p></body></html>
HTML
systemctl enable --now nginx
