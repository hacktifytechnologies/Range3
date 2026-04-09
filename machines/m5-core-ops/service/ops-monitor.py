#!/usr/bin/env python3
"""
AETHON Defense Systems — Core Operations Monitor
Machine 5: aethon-core
Runs periodic health checks and logs to /var/log/aethon/ops.log
This service runs as opsadmin but python3 binary has cap_setuid set (misconfiguration).
"""

import os
import time
import datetime
import json
import socket

LOG_DIR  = "/var/log/aethon"
LOG_FILE = os.path.join(LOG_DIR, "ops.log")
os.makedirs(LOG_DIR, exist_ok=True)

SERVICES = ["aethon-api", "aethon-dms", "redis-aethon", "apache2"]


def write_log(msg):
    ts = datetime.datetime.utcnow().isoformat()
    line = f"[{ts}] {msg}\n"
    with open(LOG_FILE, "a") as f:
        f.write(line)
    print(line, end="")


def check_services():
    """Simulate service health check."""
    results = {}
    for svc in SERVICES:
        # Simulate: in real scenario would check systemd status
        results[svc] = "UP"
    return results


def main():
    write_log("AETHON Core Operations Monitor starting...")
    hostname = socket.gethostname()
    write_log(f"Host: {hostname} | PID: {os.getpid()} | UID: {os.getuid()}")

    while True:
        checks = check_services()
        write_log("Health check: " + json.dumps(checks))
        time.sleep(60)


if __name__ == "__main__":
    main()
