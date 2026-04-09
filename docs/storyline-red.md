# OPERATION SHADOW FORGE
## Red Team Mission Briefing — CONFIDENTIAL

---

```
╔═══════════════════════════════════════════════════════════╗
║          ADVANCED PERSISTENT THREAT — UNIT 77-X           ║
║              OPERATION : SHADOW FORGE                     ║
║              CLASSIFICATION : EYES ONLY                   ║
╚═══════════════════════════════════════════════════════════╝
```

---

## THREAT ACTOR PROFILE

**Unit:** APT-77X ("Shadow Forge")
**Origin:** State-sponsored, undisclosed jurisdiction
**Motivation:** Military-industrial espionage — acquisition of F-INSAS and PGM
  blueprint data to accelerate domestic defence programme

---

## TARGET DOSSIER

**Organisation:** AETHON Defense Systems
**Description:** A global tier-1 defence contractor with active supply agreements
  across South Asia, the Middle East and Eastern Europe. AETHON develops
  Future Infantry Soldier as a System (F-INSAS) platforms and the PGM-7 Precision
  Strike Package — both of which are of extreme strategic value to your handlers.

**Intelligence indicates:**
- Their external procurement portal is running on a public-facing VM
- Internal systems (document management, dev APIs, caching infrastructure) are
  segregated but reachable through the DMZ
- Security hardening has been deferred — a Q4 pentest window recently closed
  without remediation of all findings
- A senior DevOps engineer recently modified Python3 capabilities on the core
  operations server for a "monitoring upgrade"

---

## MISSION OBJECTIVES

You are tasked with a full-chain intrusion into AETHON's infrastructure. Each
objective builds on the previous. Extract proof of access (flags) at each stage.

```
┌─────────────────────────────────────────────────────────┐
│  OBJ 1 │ Exploit AETHON's public procurement portal     │
│         │ and exfiltrate internal service credentials    │
│         │ TARGET: aethon-web (DMZ)                       │
├─────────────────────────────────────────────────────────┤
│  OBJ 2 │ Leverage harvested credentials to access       │
│         │ the internal Document Management System        │
│         │ and achieve Remote Code Execution              │
│         │ TARGET: aethon-docs (DMZ)                      │
├─────────────────────────────────────────────────────────┤
│  OBJ 3 │ Pivot to the R&D Dev API server using the      │
│         │ SSH key obtained from DMS. Exploit the API     │
│         │ to execute commands on the dev host            │
│         │ TARGET: aethon-dev (Private)                   │
├─────────────────────────────────────────────────────────┤
│  OBJ 4 │ Connect to the internal Redis cache server      │
│         │ discovered via the dev API config. Read the    │
│         │ flag and abuse Redis to gain SSH access to     │
│         │ the core operations server                     │
│         │ TARGET: aethon-cache (Private)                 │
├─────────────────────────────────────────────────────────┤
│  OBJ 5 │ Land on the core ops server and escalate to     │
│         │ root by abusing a Linux capability             │
│         │ misconfiguration. Read the final F-INSAS        │
│         │ blueprint flag                                  │
│         │ TARGET: aethon-core (Private)                  │
└─────────────────────────────────────────────────────────┘
```

---

## RULES OF ENGAGEMENT

1. Your entry point is the floating IP assigned to **aethon-web** — this is the
   only machine directly reachable from the VPN.
2. All further access must be achieved through legitimate exploitation and
   lateral movement — no brute-force on SSH credentials.
3. Do not destroy or modify flags — read and submit them.
4. Scanners (nmap, gobuster, etc.) are permitted within your allocated environment.
5. Tools available on your attack box: curl, python3, nmap, redis-cli, ssh.

---

## INTEL DROPS (hints unlocked after 30 min per stage)

| Stage | Intel                                                             |
|-------|-------------------------------------------------------------------|
| 1     | The procurement portal accepts XML. What happens with entities?  |
| 2     | Jinja2 renders user input. Search queries are reflected as HTML. |
| 3     | The Flask API accepts serialised Python objects. What format?    |
| 4     | Redis with no password on a private host. What can CONFIG do?    |
| 5     | `getcap /usr/bin/python3` — read what you find carefully.        |

---

## SUBMISSION FORMAT

Submit flags in format: `AETHON{...}` via the scoreboard portal.

*Good hunting, Shadow Forge. AETHON does not know you are coming.*
