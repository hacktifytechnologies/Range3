#!/bin/bash
# ============================================================
# AETHON Range — Machine 2 (aethon-docs) Setup Script
# Challenge: Server-Side Template Injection (SSTI) via Jinja2
# OS: Ubuntu 22.04 LTS
# ============================================================
set -e

echo "[*] AETHON Range — M2 Document Management Setup"
hostnamectl set-hostname aethon-docs

echo "[*] Updating packages..."
apt-get update -qq

echo "[*] Installing Python3, pip, venv..."
apt-get install -y python3 python3-pip python3-venv -qq

echo "[*] Creating service user: docuser..."
id -u docuser &>/dev/null || useradd -m -s /bin/bash docuser

echo "[*] Deploying Flask application..."
APP_DIR="/opt/aethon-dms"
mkdir -p $APP_DIR
cp -r /opt/aethon-setup/webapp/* $APP_DIR/
chown -R docuser:docuser $APP_DIR

echo "[*] Installing Python dependencies..."
python3 -m venv $APP_DIR/venv
$APP_DIR/venv/bin/pip install -q -r $APP_DIR/requirements.txt

echo "[*] Planting Flag 2..."
echo "AETHON{jinja2_t3mpl4t3_t4k30v3r}" > /home/docuser/flag2.txt
chmod 640 /home/docuser/flag2.txt
chown docuser:docuser /home/docuser/flag2.txt

echo "[*] Planting SSH pivot key for M3 (aethon-dev)..."
mkdir -p /home/docuser/.ssh
# This key is for the devops user on aethon-dev (M3)
# The private key is left here so a red teamer who achieves RCE via SSTI can read it
cat > /home/docuser/.ssh/id_rsa_dev << 'SSHKEY'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDSHhMTJPGTizGAIRQQJpgKiPmCEp2lUdOZ2YXEqVTEiwAAAJiy8YuYsv
GLMQAAAAJ0c3NoLWVkMjU1MTkAAAAg0h4TEyTxk4sxgCEUECaYCoj5ghKdpVHTmdmFxK
lUxIsAAAAgHmQoFg9aHxbMTYoxKnzwHkGkR7hVNq1yDGz8kIFjlYAAAAEbm9uZQAAAAA
AAAAAAAAAAQAAAAMAAAALc3NoLWVkMjU1MTkAAAAg0h4TEyTxk4sxgCEUECaYCoj5ghKd
pVHTmdmFxKlUxIsAAAAgHmQoFg9aHxbMTYoxKnzwHkGkR7hVNq1yDGz8kIFjlYAAAAA=
-----END OPENSSH PRIVATE KEY-----
SSHKEY
chmod 600 /home/docuser/.ssh/id_rsa_dev
chown -R docuser:docuser /home/docuser/.ssh

# Add a README so the attacker knows this key is useful
cat > /home/docuser/.ssh/README << 'RDEOF'
# Dev Server Access Key
# Host: aethon-dev
# User: devops
# Usage: ssh -i id_rsa_dev devops@aethon-dev
RDEOF

echo "[*] Creating systemd service..."
cat > /etc/systemd/system/aethon-dms.service << 'SVCEOF'
[Unit]
Description=AETHON Internal Document Management System
After=network.target

[Service]
Type=simple
User=docuser
WorkingDirectory=/opt/aethon-dms
ExecStart=/opt/aethon-dms/venv/bin/python3 app.py
Restart=always
RestartSec=5
Environment=FLASK_ENV=production

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable aethon-dms
systemctl start aethon-dms

echo "[*] Verifying service..."
sleep 3
systemctl status aethon-dms --no-pager | head -5

echo ""
echo "=============================================="
echo " M2 (aethon-docs) SETUP COMPLETE"
echo " DMS accessible on port 5000"
echo " Credentials: admin / Aethon@D0cs#2024"
echo " Flag 2: /home/docuser/flag2.txt"
echo " SSTI sink: /search?q=<payload>"
echo "=============================================="
