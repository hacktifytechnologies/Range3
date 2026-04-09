# AETHON DEFENSE SYSTEMS — CYBER RANGE
## Operation Shadow Forge | 5-Machine Interconnected CTF Range

---

## COMPANY PROFILE

**AETHON Defense Systems** is a global defence technology corporation
specialising in Future Infantry Soldier as a System (F-INSAS) platforms and
Precision Guided Munitions (PGMs). The range simulates an enterprise network
breach across AETHON's infrastructure.

---

## ARCHITECTURE OVERVIEW

```
INTERNET / VPN ACCESS
        │  (Wireguard — 172.24.4.0/24 floating IPs)
        │
        ▼
┌───────────────────────────────────────────────────────┐
│                v-DMZ-subnet  11.0.0.0/8               │
│                                                       │
│   ┌─────────────────────┐                             │
│   │  M1: aethon-web     │  Apache2 + PHP              │
│   │  Challenge: XXE     │  Port 80                    │
│   │  Flag: flag1.txt    │  DMZ + Pub facing           │
│   └──────────┬──────────┘                             │
│              │  Credentials via XXE                   │
│   ┌──────────▼──────────┐                             │
│   │  M2: aethon-docs    │  Flask/Jinja2 DMS           │
│   │  Challenge: SSTI    │  Port 5000                  │
│   │  Flag: flag2.txt    │  DMZ                        │
│   └──────────┬──────────┘                             │
└──────────────┼────────────────────────────────────────┘
               │  SSH key via SSTI RCE
┌──────────────┼────────────────────────────────────────┐
│              ▼  v-Priv-subnet  195.0.0.0/8            │
│   ┌─────────────────────┐                             │
│   │  M3: aethon-dev     │  Flask Pickle API           │
│   │  Challenge: Pickle  │  Port 8080                  │
│   │  Flag: flag3.txt    │  Private                    │
│   └──────────┬──────────┘                             │
│              │  Redis creds via config.ini            │
│   ┌──────────▼──────────┐                             │
│   │  M4: aethon-cache   │  Redis (no auth)            │
│   │  Challenge: Redis   │  Port 6379                  │
│   │  Flag: flag4 key    │  Private                    │
│   └──────────┬──────────┘                             │
│              │  SSH key via Redis CONFIG SET          │
│   ┌──────────▼──────────┐                             │
│   │  M5: aethon-core    │  Linux cap_setuid           │
│   │  Challenge: PrivEsc │  SSH port 22                │
│   │  Flag: flag5.txt    │  Private                    │
│   └─────────────────────┘                             │
└───────────────────────────────────────────────────────┘
```

---

## NETWORK ASSIGNMENT (OpenStack)

| Machine     | Hostname      | Network          | OpenStack Name  |
|-------------|---------------|------------------|-----------------|
| M1          | aethon-web    | v-DMZ + v-Pub    | aethon-web      |
| M2          | aethon-docs   | v-DMZ            | aethon-docs     |
| M3          | aethon-dev    | v-Priv           | aethon-dev      |
| M4          | aethon-cache  | v-Priv           | aethon-cache    |
| M5          | aethon-core   | v-Priv           | aethon-core     |

> **Important:** No IP addresses are hardcoded. All inter-machine references
> use OpenStack-assigned hostnames. Neutron's internal DNS resolves these
> within each subnet. Ensure VMs are named exactly as above in OpenStack.
> Each team gets their own snapshot copy — IPs will differ per team.

---

## REPOSITORY STRUCTURE

```
aethon-range/
├── README.md                        ← You are here
├── docs/
│   ├── storyline-red.md             ← Red team mission briefing
│   ├── storyline-blue.md            ← Blue team mission briefing
│   └── network-diagram.md           ← Detailed network topology
├── challenges/
│   ├── c1-red.md / c1-blue.md       ← Per-challenge descriptions
│   ├── c2-red.md / c2-blue.md
│   ├── c3-red.md / c3-blue.md
│   ├── c4-red.md / c4-blue.md
│   └── c5-red.md / c5-blue.md
├── machines/
│   ├── m1-web-portal/               ← Apache/PHP XXE portal
│   │   ├── setup/setup.sh
│   │   └── webapp/
│   ├── m2-doc-mgmt/                 ← Flask SSTI DMS
│   │   ├── setup/setup.sh
│   │   └── webapp/
│   ├── m3-dev-api/                  ← Flask Pickle API
│   │   ├── setup/setup.sh
│   │   └── service/
│   ├── m4-cache/                    ← Redis (no auth)
│   │   └── setup/setup.sh
│   └── m5-core-ops/                 ← Linux cap_setuid
│       ├── setup/setup.sh
│       └── service/
├── ttps/
│   ├── blue/                        ← 5 attack TTPs for blue log gen
│   │   ├── b1-xxe-attack.yml
│   │   ├── b2-ssti-exploit.yml
│   │   ├── b3-pickle-deser.yml
│   │   ├── b4-redis-rce.yml
│   │   └── b5-capability-abuse.yml
│   └── red/                         ← 5 setup TTPs for range config
│       ├── r1-deploy-xxe-app.yml
│       ├── r2-deploy-ssti-app.yml
│       ├── r3-deploy-pickle-api.yml
│       ├── r4-configure-redis.yml
│       └── r5-setup-caps.yml
└── solution/
    └── full-solution-guide.md       ← Complete walkthrough (admin only)
```

---

## QUICK SETUP GUIDE

### Step 1 — Provision VMs in OpenStack
- Create 5 Ubuntu 22.04 LTS VMs named exactly:
  `aethon-web`, `aethon-docs`, `aethon-dev`, `aethon-cache`, `aethon-core`
- Assign networks per table above
- Assign a floating IP (172.24.4.0/24) to `aethon-web` for participant access

### Step 2 — Generate SSH keypair for M2→M3 pivot
```bash
ssh-keygen -t ed25519 -f keys/id_rsa_dev -N ""
# Place id_rsa_dev  → machines/m2-doc-mgmt/setup (as /opt/aethon-setup/keys/id_rsa_dev)
# Place id_rsa_dev.pub → machines/m3-dev-api/setup (as /opt/aethon-setup/keys/id_rsa_dev.pub)
```

### Step 3 — Upload and run setup scripts on each VM
```bash
# On each VM: upload the corresponding machines/mX-*/  directory to /opt/aethon-setup/
# Then run:
sudo bash /opt/aethon-setup/setup/setup.sh
```

### Step 4 — Snapshot each VM
Once all 5 are set up and running, snapshot the full set and provision per team.

### Step 5 — Verify
```bash
curl http://<aethon-web-floating-ip>/          # Should show AETHON homepage
curl http://<aethon-web-floating-ip>/api/submit-procurement.php  # Should return 405
```

---

## FLAGS SUMMARY

| Challenge | Machine       | Flag                                       |
|-----------|---------------|--------------------------------------------|
| 1 — XXE   | aethon-web    | `AETHON{xxe_r34ds_4ll_s3cr3ts_v3nd0r}`    |
| 2 — SSTI  | aethon-docs   | `AETHON{jinja2_t3mpl4t3_t4k30v3r}`        |
| 3 — Pickle| aethon-dev    | `AETHON{p1ckl3_d3s3r14l1z4t10n_rce}`      |
| 4 — Redis | aethon-cache  | `AETHON{r3d1s_unauth_pr1v3sc_via_ssh}`    |
| 5 — PrivEsc| aethon-core  | `AETHON{c4p4b1l1ty_4bus3_r00t_0wn3d_f1n4l}` |

---

*AETHON Defense Systems range — designed for intermediate-level red/blue team training.*
*All vulnerabilities are intentional. Do not deploy on public infrastructure.*
