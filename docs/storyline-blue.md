# OPERATION IRON SENTINEL
## Blue Team Mission Briefing — AETHON SOC

---

```
╔═══════════════════════════════════════════════════════════╗
║       AETHON DEFENSE SYSTEMS — SECURITY OPERATIONS        ║
║           OPERATION : IRON SENTINEL                       ║
║           THREAT LEVEL : CRITICAL — APT INTRUSION        ║
╚═══════════════════════════════════════════════════════════╝
```

---

## SITUATION REPORT

**Date:** Classified
**Classification:** RESTRICTED — SOC Distribution Only

AETHON Threat Intelligence has received credible reporting that state-sponsored
APT group "Shadow Forge" (APT-77X) has identified AETHON Defense Systems as a
high-priority target. Their objective is to extract F-INSAS and PGM blueprint
data via a full-chain network intrusion.

Your team is the last line of defence. The network is LIVE. The attacker may
already be inside.

---

## YOUR ROLE

You are part of AETHON's Security Operations Centre (SOC). Your mission is to
**detect, investigate, and document** each stage of the attacker's intrusion
across all five machines. You will use the **Caldera blue-team TTPs** provided
to simulate the attack and generate logs before monitoring each machine.

> **Note:** The same range environment is used for both teams.
> Blue team receives the Caldera attack TTPs (b1–b5) to run the attack
> simulation and generate log telemetry for detection exercises.

---

## DETECTION OBJECTIVES

```
┌─────────────────────────────────────────────────────────────┐
│ DETECT 1 │ XXE attack on procurement portal                  │
│           │ Machine: aethon-web                              │
│           │ Artefacts: Apache access.log, PHP error.log      │
│           │ IOC: POST /api/submit-procurement.php            │
│           │      XML body containing DOCTYPE + ENTITY refs   │
├─────────────────────────────────────────────────────────────┤
│ DETECT 2 │ SSTI exploitation on document management          │
│           │ Machine: aethon-docs                             │
│           │ Artefacts: Flask app log, systemd journal        │
│           │ IOC: GET /search?q= with {{ }} template syntax   │
│           │      os.popen() / subprocess calls in log        │
├─────────────────────────────────────────────────────────────┤
│ DETECT 3 │ Pickle deserialization RCE on dev API             │
│           │ Machine: aethon-dev                              │
│           │ Artefacts: Flask access log, auditd (if enabled) │
│           │ IOC: POST /api/load-profile with base64 body     │
│           │      Unexpected child processes spawned by Flask │
├─────────────────────────────────────────────────────────────┤
│ DETECT 4 │ Unauthorised Redis access + CONFIG SET abuse      │
│           │ Machine: aethon-cache                            │
│           │ Artefacts: /var/log/redis/redis-server.log       │
│           │ IOC: CONFIG SET dir + dbfilename commands        │
│           │      BGSAVE from non-localhost client            │
├─────────────────────────────────────────────────────────────┤
│ DETECT 5 │ Privilege escalation via cap_setuid on python3    │
│           │ Machine: aethon-core                             │
│           │ Artefacts: auditd log, /var/log/auth.log         │
│           │ IOC: setuid(0) syscall from python3 process      │
│           │      python3 spawning /bin/bash as UID 0         │
└─────────────────────────────────────────────────────────────┘
```

---

## LOG LOCATIONS PER MACHINE

| Machine       | Key Log Files                                          |
|---------------|--------------------------------------------------------|
| aethon-web    | `/var/log/apache2/aethon_access.log`                   |
|               | `/var/log/apache2/aethon_error.log`                    |
| aethon-docs   | `journalctl -u aethon-dms`                             |
|               | `/opt/aethon-dms/` (app stdout via journald)           |
| aethon-dev    | `journalctl -u aethon-api`                             |
|               | `/opt/aethon-api/` (app stdout via journald)           |
| aethon-cache  | `/var/log/redis/redis-server.log`                      |
| aethon-core   | `/var/log/aethon/ops.log`                              |
|               | `/var/log/auth.log`                                    |
|               | `journalctl -u aethon-core-monitor`                    |

---

## USING CALDERA FOR LOG GENERATION

Before starting your detection exercise, run the Blue TTPs (b1–b5) using
Caldera to simulate the attack and generate realistic log telemetry:

1. Import TTPs from `ttps/blue/` into your Caldera instance
2. Create an operation targeting each machine in sequence
3. Run TTPs in order: b1 → b2 → b3 → b4 → b5
4. Collect logs from each machine
5. Analyse the logs to identify attacker TTPs and write detection rules

---

## DETECTION RULE WRITING EXERCISE

For each stage, write a detection rule in the format of your choice
(Sigma, Splunk SPL, ELK KQL, or plain grep) that would catch the IOC.

**Example (Stage 1 — XXE):**
```
# Apache log grep
grep -E "POST.*submit-procurement\.php" /var/log/apache2/aethon_access.log

# Sigma rule concept:
# logsource: webserver
# detection:
#   keywords: ['DOCTYPE', 'ENTITY', 'SYSTEM', 'file://']
#   condition: keywords
```

---

## SCORING FOR BLUE TEAM

| Task                                       | Points |
|--------------------------------------------|--------|
| Correctly identify each attack stage (×5)  | 50 pts |
| Write detection rule per stage (×5)        | 50 pts |
| Identify attacker lateral movement path    | 20 pts |
| Propose remediation per vulnerability (×5) | 30 pts |
| **Total**                                  | **150 pts** |

---

*AETHON SOC — You are the shield. Hold the line.*
