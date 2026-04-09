#!/bin/bash
# ============================================================
# AETHON Range — Machine 4 (aethon-cache) Setup Script
# Challenge: Unauthenticated Redis → Write SSH Authorized Keys
# OS: Ubuntu 22.04 LTS
# ============================================================
set -e

echo "[*] AETHON Range — M4 Cache Server Setup"
hostnamectl set-hostname aethon-cache

apt-get update -qq
apt-get install -y redis-server openssh-server -qq

echo "[*] Creating cache service user..."
id -u cacheops &>/dev/null || useradd -m -s /bin/bash cacheops

echo "[*] Configuring Redis WITHOUT authentication (misconfiguration for challenge)..."
cat > /etc/redis/redis.conf << 'REDISEOF'
# AETHON Telemetry Cache — Redis Configuration
# SECURITY NOTE: requirepass disabled for internal network perf — AETHON-INFRA-2023-09
# TODO: enable auth before external audit

bind 0.0.0.0
protected-mode no
port 6379
daemonize no
loglevel notice
logfile /var/log/redis/redis-server.log
dir /var/lib/redis
dbfilename dump.rdb
save 900 1
save 300 10
save 60 10000
REDISEOF

echo "[*] Setting up /var/lib/redis owned by redis user for CONFIG SET dir attack..."
chown redis:redis /var/lib/redis
chmod 777 /var/lib/redis

echo "[*] Ensuring cacheops home dir is writeable by redis (for SSH key injection)..."
mkdir -p /home/cacheops/.ssh
chmod 777 /home/cacheops/.ssh
chown cacheops:cacheops /home/cacheops
# Redis user needs to write authorized_keys to cacheops home
# This simulates a misconfigured shared-host setup
chmod 777 /home/cacheops

echo "[*] Planting Flag 4 as a Redis key (loaded at startup)..."
# We'll use redis-cli after startup to SET the flag
# Also plant it as a file as backup
echo "AETHON{r3d1s_unauth_pr1v3sc_via_ssh}" > /home/cacheops/flag4.txt
chmod 644 /home/cacheops/flag4.txt
chown cacheops:cacheops /home/cacheops/flag4.txt

echo "[*] Configuring systemd for Redis..."
cat > /etc/systemd/system/redis-aethon.service << 'SVCEOF'
[Unit]
Description=AETHON Telemetry Cache (Redis)
After=network.target

[Service]
Type=simple
User=redis
ExecStart=/usr/bin/redis-server /etc/redis/redis.conf
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable redis-aethon
systemctl start redis-aethon
sleep 2

echo "[*] Seeding Redis with AETHON telemetry data and flag..."
redis-cli -p 6379 SET "aethon:flag4" "AETHON{r3d1s_unauth_pr1v3sc_via_ssh}"
redis-cli -p 6379 SET "aethon:telemetry:pgm7:sessions_today" "84"
redis-cli -p 6379 SET "aethon:telemetry:finsas:units_active" "312"
redis-cli -p 6379 SET "aethon:config:core_host" "aethon-core"
redis-cli -p 6379 SET "aethon:config:core_user" "opsadmin"
redis-cli -p 6379 HSET "aethon:hosts" "core" "aethon-core" "web" "aethon-web" "docs" "aethon-docs"

echo "[*] Enabling SSH..."
systemctl enable ssh
systemctl start ssh

echo ""
echo "=============================================="
echo " M4 (aethon-cache) SETUP COMPLETE"
echo " Redis on port 6379 (NO AUTH)"
echo " Flag 4: redis GET aethon:flag4"
echo " Also: /home/cacheops/flag4.txt"
echo " SSH key write path: /home/cacheops/.ssh/authorized_keys"
echo "=============================================="
