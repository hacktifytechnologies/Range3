# Challenge 2 — Detect: SSTI on Document Management System
## Operation Iron Sentinel | Detection Stage 2 of 5
### Machine: aethon-docs | Attack: Jinja2 Server-Side Template Injection

---

**SCENARIO**
The attacker has authenticated to the internal DMS and is probing the search
functionality for template injection (MITRE T1059.006).

**YOUR TASK**
1. Run Caldera TTP `b2-ssti-exploit.yml` to generate attack logs on aethon-docs
2. Examine Flask application logs via journald
3. Identify the SSTI payload and the commands executed

**LOG INVESTIGATION COMMANDS**
```bash
# On aethon-docs — Flask app logs via systemd
journalctl -u aethon-dms -f

# Filter search requests
journalctl -u aethon-dms | grep "GET /search"

# Look for template execution artefacts
journalctl -u aethon-dms | grep -E "\{\{|\}\}|popen|subprocess|__class__"
```

**KEY IOCs TO IDENTIFY**
- GET `/search?q=` with `{{` and `}}` in the query string (URL-encoded: `%7B%7B`)
- Query strings containing `__class__`, `__mro__`, `__globals__`, `os.popen`
- Application output containing system command results (e.g., `uid=` from `id`)
- File read operations on `/home/docuser/.ssh/` paths

**DETECTION RULE (write your own)**
Draft a rule to detect SSTI attempts. Consider: URL parameter pattern matching
for Jinja2 template delimiters, anomalous response content.

**REMEDIATION**
Identify the line in `app.py` that is vulnerable and document the fix.
(Hint: Which Flask function renders user input as a template string?)

**SCORING TASKS**
- [ ] Identify the authentication event and the SSTI probe request in logs
- [ ] Extract the full SSTI payload used
- [ ] Document which system commands were executed via RCE
- [ ] Write a detection rule
- [ ] Propose correct code remediation
