#!/bin/bash
# ============================================================
# AETHON Range — Machine 5 (aethon-core) Setup Script
# Challenge: Linux Capabilities Abuse (cap_setuid on python3)
# OS: Ubuntu 22.04 LTS
# ============================================================
set -e

echo "[*] AETHON Range — M5 Core Ops Setup"
hostnamectl set-hostname aethon-core

apt-get update -qq
apt-get install -y python3 openssh-server libcap2-bin -qq

echo "[*] Creating opsadmin user (SSH pivot target from M4)..."
id -u opsadmin &>/dev/null || useradd -m -s /bin/bash opsadmin

echo "[*] Setting up SSH authorized_keys for opsadmin..."
# This key will be injected by the attacker via M4 Redis CONFIG SET.
# We pre-create the .ssh dir with correct permissions so Redis can write to it.
mkdir -p /home/opsadmin/.ssh
chmod 700 /home/opsadmin/.ssh
chown -R opsadmin:opsadmin /home/opsadmin/.ssh
# authorized_keys will be written by the attacker via Redis CONFIG SET

echo "[*] Deploying ops-monitor service..."
APP_DIR="/opt/aethon-core"
mkdir -p $APP_DIR
cp /opt/aethon-setup/service/ops-monitor.py $APP_DIR/
chown -R opsadmin:opsadmin $APP_DIR

echo "[*] Setting Python3 capability — cap_setuid (the misconfiguration)..."
PYTHON3_PATH=$(which python3)
setcap cap_setuid+ep $PYTHON3_PATH
echo "[+] cap_setuid set on $PYTHON3_PATH"
getcap $PYTHON3_PATH

echo "[*] Planting Flag 5 (only readable by root)..."
echo "AETHON{c4p4b1l1ty_4bus3_r00t_0wn3d_f1n4l}" > /root/flag5.txt
chmod 400 /root/flag5.txt

echo "[*] Planting a note for opsadmin (breadcrumb)..."
cat > /home/opsadmin/NOTICE.txt << 'NOTEEOF'
AETHON CORE OPERATIONS SERVER
==============================
Role      : Centralized ops monitoring node
Contact   : noc@aethon-internal
Note      : Python3 upgraded for telemetry module compatibility.
            Do not modify python3 capabilities without NOC approval.
            See: AETHON-INFRA-CHANGE-2024-118

Sensitive data is stored under /root/. Access restricted to root only.
NOTEEOF
chown opsadmin:opsadmin /home/opsadmin/NOTICE.txt

echo "[*] Creating ops-monitor systemd service..."
cat > /etc/systemd/system/aethon-core-monitor.service << 'SVCEOF'
[Unit]
Description=AETHON Core Operations Monitor
After=network.target

[Service]
Type=simple
User=opsadmin
WorkingDirectory=/opt/aethon-core
ExecStart=/usr/bin/python3 /opt/aethon-core/ops-monitor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable aethon-core-monitor
systemctl start aethon-core-monitor

echo "[*] Enabling SSH..."
systemctl enable ssh
systemctl start ssh

echo ""
echo "=============================================="
echo " M5 (aethon-core) SETUP COMPLETE"
echo " SSH on port 22 (key via Redis from M4)"
echo " Flag 5: /root/flag5.txt (root only)"
echo " PrivEsc path: python3 has cap_setuid"
echo "   python3 -c \"import os; os.setuid(0); os.system('/bin/bash')\""
echo "=============================================="
