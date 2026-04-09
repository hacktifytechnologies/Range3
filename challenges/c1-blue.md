# Challenge 1 — Detect: XXE on Procurement Portal
## Operation Iron Sentinel | Detection Stage 1 of 5
### Machine: aethon-web | Attack: XML External Entity Injection

---

**SCENARIO**
Threat actor Shadow Forge is targeting AETHON's public procurement portal.
Intelligence suggests they will attempt to exploit the XML upload endpoint to
read internal files via XXE (MITRE T1190).

**YOUR TASK**
1. Run Caldera TTP `b1-xxe-attack.yml` against aethon-web to generate log data
2. Examine Apache logs for signs of the XXE attack
3. Write a detection rule that would catch this in a SIEM

**LOG INVESTIGATION COMMANDS**
```bash
# On aethon-web — watch Apache access log
tail -f /var/log/apache2/aethon_access.log

# Filter for POST requests to the procurement endpoint
grep "POST.*submit-procurement" /var/log/apache2/aethon_access.log

# Check PHP error log for libxml entity loading warnings
grep -i "entity\|ENTITY\|DOCTYPE\|libxml" /var/log/apache2/aethon_error.log
```

**KEY IOCs TO IDENTIFY**
- POST requests to `/api/submit-procurement.php` with unusual payload sizes
- XML body containing `<!DOCTYPE` declarations
- XML body containing `<!ENTITY` with `SYSTEM` keyword and `file://` URI
- Response body containing file system content (e.g., `/etc/passwd` or config)

**DETECTION RULE (write your own)**
Draft a Sigma or KQL rule to alert on XXE attempts against this endpoint.
Consider: request size anomaly, XML body keyword matching, response size anomaly.

**REMEDIATION**
Identify and document what change to `submit-procurement.php` would prevent XXE.
(Hint: What PHP flag should be removed or what function call should be added?)

**SCORING TASKS**
- [ ] Identify the exact request that constitutes the XXE attack from logs
- [ ] Extract the attacker's XXE payload from the log entry
- [ ] Write a detection rule (any format)
- [ ] Propose the correct code-level remediation
