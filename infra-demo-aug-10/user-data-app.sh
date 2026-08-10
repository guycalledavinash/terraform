#!/bin/bash
set -euxo pipefail
dnf install -y nodejs
mkdir -p /opt/three-tier-app
cat >/opt/three-tier-app/server.js <<'JS'
const http = require('http');
const server = http.createServer((req, res) => {
  if (req.url === '/health') { res.writeHead(200); res.end('ok'); return; }
  res.writeHead(200, {'Content-Type':'application/json'});
  res.end(JSON.stringify({service:'infra-demo-aug-10-app', database:'${db_host}', name:'${db_name}'}));
});
server.listen(4000, '0.0.0.0');
JS
cat >/etc/systemd/system/three-tier-app.service <<'UNIT'
[Unit]
Description=Demo app tier
After=network.target
[Service]
ExecStart=/usr/bin/node /opt/three-tier-app/server.js
Restart=always
User=ec2-user
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now three-tier-app
