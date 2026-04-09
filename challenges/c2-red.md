# Challenge 2 — Credential Access + Execution
## Operation Shadow Forge | Stage 2 of 5
### Machine: aethon-docs | Vulnerability: Server-Side Template Injection (SSTI)

---

**SITUATION**
Using the credentials harvested from the M1 XXE attack, you can now access
AETHON's internal Document Management System running on `aethon-docs:5000`.
The system is a Flask/Jinja2 application. Initial recon shows a search feature.

**CREDENTIALS (from Stage 1)**
- URL: `http://<aethon-docs>:5000/`
- Username: `admin`
- Password: obtained from `/var/www/html/config/internal.xml` via XXE

**YOUR OBJECTIVE**
1. Log in to the DMS
2. Find and exploit the SSTI vulnerability to achieve Remote Code Execution
3. Read the flag and exfiltrate the SSH private key for the next machine

**HINTS (unlock after 30 min)**
1. Navigate to the `/search` endpoint and try entering `{{7*7}}` — if you
   see `49` reflected, the template engine is executing your input.
2. Escalate from math expressions to OS command execution. Research
   Jinja2 SSTI payloads that use `__class__.__mro__` or `config` globals.
3. Once you have RCE, run: `ls /home/docuser/.ssh/` and read the key files.

**EXAMPLE SSTI PAYLOAD STRUCTURE**
```
{{config.__class__.__init__.__globals__['os'].popen('COMMAND').read()}}
```

**WHAT TO SUBMIT**
Flag: `AETHON{...}` found at `/home/docuser/flag2.txt`

**PIVOT INTEL**
Read `/home/docuser/.ssh/id_rsa_dev` — this is the private key for `devops@aethon-dev`.
Also read `/home/docuser/.ssh/README` for the target hostname and user.

---
*Next: SSH to aethon-dev as devops using the key you just exfiltrated*
