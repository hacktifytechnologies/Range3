#!/bin/bash
# ============================================================
# AETHON Range — Machine 3 (aethon-dev) Setup Script
# Challenge: Python Pickle Deserialization RCE
# OS: Ubuntu 22.04 LTS
# ============================================================
set -e

echo "[*] AETHON Range — M3 Dev API Setup"
hostnamectl set-hostname aethon-dev

apt-get update -qq
apt-get install -y python3 python3-pip python3-venv openssh-server -qq

echo "[*] Creating devops user (SSH pivot target)..."
id -u devops &>/dev/null || useradd -m -s /bin/bash devops

echo "[*] Setting up SSH access for devops (key from M2)..."
mkdir -p /home/devops/.ssh
chmod 700 /home/devops/.ssh

# Generate or accept the keypair. In the range, the public key
# corresponding to the private key planted on M2 must be installed here.
# The admin should run: ssh-keygen -t ed25519 -f /tmp/dev_key -N ""
# Then put the public key below. For simplicity we use a pre-generated pair.
cat > /home/devops/.ssh/authorized_keys << 'PUBKEY'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINIeExMk8ZOLMYAhFBAmGAqI+YISnKVR05nZhcSpVMSL devops-pivot-key
PUBKEY

chmod 600 /home/devops/.ssh/authorized_keys
chown -R devops:devops /home/devops/.ssh

echo "[*] Deploying API service..."
APP_DIR="/opt/aethon-api"
mkdir -p $APP_DIR
cp /opt/aethon-setup/service/* $APP_DIR/
chown -R devops:devops $APP_DIR

python3 -m venv $APP_DIR/venv
$APP_DIR/venv/bin/pip install -q -r $APP_DIR/requirements.txt

echo "[*] Planting Flag 3..."
echo "AETHON{p1ckl3_d3s3r14l1z4t10n_rce}" > /opt/aethon-api/flag3.txt
chmod 640 /opt/aethon-api/flag3.txt
chown devops:devops /opt/aethon-api/flag3.txt

echo "[*] Creating systemd service..."
cat > /etc/systemd/system/aethon-api.service << 'SVCEOF'
[Unit]
Description=AETHON R&D Field Analyst API
After=network.target

[Service]
Type=simple
User=devops
WorkingDirectory=/opt/aethon-api
ExecStart=/opt/aethon-api/venv/bin/python3 api.py
Restart=always
RestartSec=5
EnvironmentFile=-/opt/aethon-api/config.ini

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable aethon-api
systemctl start aethon-api

echo "[*] Ensuring SSH is running..."
systemctl enable ssh
systemctl start ssh

echo ""
echo "=============================================="
echo " M3 (aethon-dev) SETUP COMPLETE"
echo " API service on port 8080"
echo " SSH on port 22 (key from M2)"
echo " Flag 3: /opt/aethon-api/flag3.txt"
echo " Pickle sink: POST /api/load-profile"
echo "=============================================="
