# Challenge 5 — Detect: Linux Capability Abuse (cap_setuid)
## Operation Iron Sentinel | Detection Stage 5 of 5
### Machine: aethon-core | Attack: Python3 cap_setuid Privilege Escalation

---

**SCENARIO**
The attacker has landed on aethon-core as opsadmin and is exploiting a
misconfigured Linux capability on python3 to escalate to root
(MITRE T1548 — Abuse Elevation Control Mechanism).

**YOUR TASK**
1. Run Caldera TTP `b5-capability-abuse.yml` to simulate the escalation
2. Examine auth logs and audit events for privilege change
3. Verify and document the capability misconfiguration

**LOG INVESTIGATION COMMANDS**
```bash
# On aethon-core — Auth log
tail -f /var/log/auth.log

# Auditd — setuid syscall events (if auditd installed and configured)
ausearch -sc setuid -ts recent 2>/dev/null

# Check current python3 capabilities
getcap /usr/bin/python3

# Look for root-owned processes spawned by opsadmin session
ps aux | grep -E "root.*python|root.*bash" | grep -v "^root"

# Ops monitor log (attacker may have written to it)
tail -20 /var/log/aethon/ops.log
```

**KEY IOCs TO IDENTIFY**
- `python3` process owned by opsadmin performing `setuid(0)` syscall
- Shell or command execution as UID 0 with parent process being python3
- Read access to `/root/flag5.txt` or `/root/` by a non-root session
- `getcap` command execution during enumeration phase

**CAPABILITY AUDIT COMMANDS**
```bash
# Find all binaries with capabilities set (run as root for full output)
find / -xdev 2>/dev/null | xargs getcap 2>/dev/null

# Remove the misconfigured capability (remediation)
setcap -r /usr/bin/python3
```

**DETECTION RULE (write your own)**
Alert on: python3 or interpreter process calling setuid(0), UID transitions
from non-zero to zero outside sudo/su, getcap enumeration commands.

**REMEDIATION**
1. Remove cap_setuid from python3: `setcap -r /usr/bin/python3`
2. Audit all binaries with capabilities: `find / -xdev | xargs getcap 2>/dev/null`
3. Implement auditd rules to monitor setuid syscalls
4. Principle of least privilege: use a dedicated low-privilege service account
   for the ops-monitor service; do NOT grant capabilities to system-wide binaries.

**SCORING TASKS**
- [ ] Confirm the capability is present on python3 before remediation
- [ ] Identify the exact exploit command in logs
- [ ] Capture the UID transition event (non-root → root)
- [ ] Write a detection rule
- [ ] Execute and document the remediation step
