# Challenge 3 — Detect: Pickle Deserialization on Dev API
## Operation Iron Sentinel | Detection Stage 3 of 5
### Machine: aethon-dev | Attack: Python Insecure Deserialization

---

**SCENARIO**
The attacker has pivoted to aethon-dev via SSH and is now exploiting the
R&D API's pickle deserialization endpoint (MITRE T1059.006).

**YOUR TASK**
1. Run Caldera TTP `b3-pickle-deser.yml` to generate attack telemetry
2. Examine API logs and process creation events
3. Identify the deserialization attack and resulting OS command execution

**LOG INVESTIGATION COMMANDS**
```bash
# Flask API logs
journalctl -u aethon-api -f

# Check for unexpected processes spawned by the Flask process
ps aux | grep -E "devops|python"

# Audit log (if auditd enabled)
ausearch -c python3 -ts recent 2>/dev/null

# Check for artefact files written by the exploit
ls -la /tmp/*.txt 2>/dev/null
```

**KEY IOCs TO IDENTIFY**
- POST `/api/load-profile` with a large base64-encoded body
- Flask process spawning unexpected child processes (sh, bash, id, cat)
- Files written to /tmp/ by the devops user outside normal operation
- Unusual file reads in /opt/aethon-api/ (config.ini, flag3.txt)

**DETECTION RULE (write your own)**
Consider: anomalous POST body size to /api/load-profile, child process spawning
from python3, unexpected file creation in /tmp by service user.

**REMEDIATION**
What should replace `pickle.loads()` in the API? What safer serialization
format should AETHON use for profile data? Document your recommendation.

**SCORING TASKS**
- [ ] Identify the malicious API call in logs
- [ ] Determine what OS command the attacker executed
- [ ] Identify what data was exfiltrated (config.ini contents)
- [ ] Write a detection rule
- [ ] Propose remediation
