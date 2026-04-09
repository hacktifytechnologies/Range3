# AETHON RANGE — NETWORK DIAGRAM & TOPOLOGY

## OpenStack Network Layout

```
╔══════════════════════════════════════════════════════════════════════════╗
║  FLOATING NETWORK  172.24.4.0/24  (WireGuard VPN access from outside)   ║
║                                                                          ║
║    Floating IP ──► aethon-web (M1 only)                                 ║
╚══════════════════════════════════════════════════════════════════════════╝
                          │
                          │ NAT / Floating IP
                          ▼
╔══════════════════════════════════════════════════════════════════════════╗
║  v-Pub-subnet    203.0.0.0/8   (Virtual Public)                         ║
║                                                                          ║
║  ┌────────────────────────────────────────────────────────────────────┐  ║
║  │  M1: aethon-web                                                    │  ║
║  │  ● Apache2 + PHP 8.1                                               │  ║
║  │  ● Port 80  — AETHON Procurement Portal                            │  ║
║  │  ● Vulnerability: XXE (LIBXML_NOENT enabled)                       │  ║
║  │  ● Files: /var/www/html/config/internal.xml (planted credentials)  │  ║
║  │  ● Flag 1: /etc/flag1.txt                                          │  ║
║  └────────────────────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════════╤════════════════════════════════╝
                                        │ Also on v-DMZ-subnet
                                        ▼
╔══════════════════════════════════════════════════════════════════════════╗
║  v-DMZ-subnet    11.0.0.0/8    (DMZ)                                    ║
║                                                                          ║
║  M1: aethon-web ─────────────────────────────────────────────────────   ║
║       (has both v-Pub and v-DMZ interfaces)                             ║
║                                │                                         ║
║                   credentials via XXE                                   ║
║                                │                                         ║
║                                ▼                                         ║
║  ┌────────────────────────────────────────────────────────────────────┐  ║
║  │  M2: aethon-docs                                                   │  ║
║  │  ● Python 3 + Flask + Jinja2                                       │  ║
║  │  ● Port 5000 — Internal Document Management System                 │  ║
║  │  ● Auth: admin / Aethon@D0cs#2024 (from M1 XXE)                   │  ║
║  │  ● Vulnerability: SSTI — render_template_string(user_input)        │  ║
║  │  ● Flag 2: /home/docuser/flag2.txt                                 │  ║
║  │  ● Pivot: /home/docuser/.ssh/id_rsa_dev (SSH key to M3)           │  ║
║  └────────────────────────────────────────────────────────────────────┘  ║
╚═══════════════════════════════════════╤════════════════════════════════╝
                                        │ SSH key → devops@aethon-dev
                                        ▼
╔══════════════════════════════════════════════════════════════════════════╗
║  v-Priv-subnet   195.0.0.0/8   (Private Internal)                       ║
║                                                                          ║
║  ┌────────────────────────────────────────────────────────────────────┐  ║
║  │  M3: aethon-dev                                                    │  ║
║  │  ● Python 3 + Flask                                                │  ║
║  │  ● Port 8080 — R&D Field Analyst API                               │  ║
║  │  ● Port 22   — SSH (key from M2)                                   │  ║
║  │  ● Vulnerability: Pickle Deserialization on /api/load-profile      │  ║
║  │  ● Flag 3: /opt/aethon-api/flag3.txt                               │  ║
║  │  ● Pivot: /opt/aethon-api/config.ini → aethon-cache:6379           │  ║
║  └────────────────────────────────────────────────────────────────────┘  ║
║                                │                                         ║
║               redis-cli (no auth)                                       ║
║                                │                                         ║
║                                ▼                                         ║
║  ┌────────────────────────────────────────────────────────────────────┐  ║
║  │  M4: aethon-cache                                                  │  ║
║  │  ● Redis (no requirepass, bind 0.0.0.0)                            │  ║
║  │  ● Port 6379 — Redis (unauthenticated)                             │  ║
║  │  ● Vulnerability: CONFIG SET dir → SSH key injection               │  ║
║  │  ● Flag 4: redis GET aethon:flag4                                  │  ║
║  │  ● Pivot: Redis keys → aethon-core:opsadmin                        │  ║
║  └────────────────────────────────────────────────────────────────────┘  ║
║                                │                                         ║
║                    SSH key → opsadmin@aethon-core                       ║
║                                │                                         ║
║                                ▼                                         ║
║  ┌────────────────────────────────────────────────────────────────────┐  ║
║  │  M5: aethon-core                                                   │  ║
║  │  ● Ubuntu 22.04 + Python 3                                         │  ║
║  │  ● Port 22 — SSH (opsadmin)                                        │  ║
║  │  ● Vulnerability: python3 cap_setuid+ep → os.setuid(0) → root     │  ║
║  │  ● Flag 5: /root/flag5.txt (root only)                             │  ║
║  └────────────────────────────────────────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════════╝
```

---

## Machine Specifications

| VM Name       | Hostname      | Subnet(s)         | Services            | Ports       |
|---------------|---------------|-------------------|---------------------|-------------|
| aethon-web    | aethon-web    | v-Pub + v-DMZ     | Apache2, PHP 8.1    | 80, 22      |
| aethon-docs   | aethon-docs   | v-DMZ             | Flask, Python3      | 5000, 22    |
| aethon-dev    | aethon-dev    | v-Priv            | Flask API, Python3  | 8080, 22    |
| aethon-cache  | aethon-cache  | v-Priv            | Redis               | 6379, 22    |
| aethon-core   | aethon-core   | v-Priv            | Python3, SSH        | 22          |

---

## OpenStack Security Group Rules

### aethon-web SG
| Direction | Protocol | Port | Source          |
|-----------|----------|------|-----------------|
| Ingress   | TCP      | 80   | 0.0.0.0/0       |
| Ingress   | TCP      | 22   | 172.24.4.0/24   |
| Egress    | ALL      | ALL  | 0.0.0.0/0       |

### aethon-docs SG
| Direction | Protocol | Port | Source          |
|-----------|----------|------|-----------------|
| Ingress   | TCP      | 5000 | 11.0.0.0/8      |
| Ingress   | TCP      | 22   | 172.24.4.0/24   |
| Egress    | ALL      | ALL  | 0.0.0.0/0       |

### aethon-dev / aethon-cache / aethon-core SG
| Direction | Protocol | Port | Source          |
|-----------|----------|------|-----------------|
| Ingress   | TCP      | 22   | 172.24.4.0/24   |
| Ingress   | TCP      | 8080 | 195.0.0.0/8     |
| Ingress   | TCP      | 6379 | 195.0.0.0/8     |
| Egress    | ALL      | ALL  | 0.0.0.0/0       |

---

## Important Notes — No IP Hardcoding

All machines use their OpenStack-assigned **hostnames** for inter-service
discovery. OpenStack Neutron provides internal DNS resolution so that
`aethon-docs`, `aethon-cache`, etc. resolve within the same subnet.

When snapshotting and provisioning for multiple teams:
- Each team's 5 VMs get different IPs automatically via DHCP
- Hostnames remain the same (aethon-web, aethon-docs, etc.)
- Internal DNS resolves correctly within each team's network
- No config files need modification between team deployments
