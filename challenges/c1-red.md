# Challenge 1 — Initial Access
## Operation Shadow Forge | Stage 1 of 5
### Machine: aethon-web | Vulnerability: XML External Entity (XXE) Injection

---

**SITUATION**
AETHON Defense Systems operates an internet-facing procurement portal at
`http://<aethon-web>/`. Registered vendors submit procurement requests as XML
documents through the portal. Your OSINT reveals the portal runs PHP on Apache.

**YOUR OBJECTIVE**
Exploit the XML parser to read a sensitive internal configuration file and
extract credentials for AETHON's internal Document Management System.

**ENTRY POINT**
- URL: `http://<aethon-web>/procurement.html`
- API endpoint: `POST /api/submit-procurement.php`
- Content-Type: `application/xml`

**HINTS (unlock after 30 min)**
1. The server parses XML with entity expansion enabled — what happens if you
   define an external entity pointing to a local file?
2. Try reading `/etc/passwd` first to confirm XXE, then look for config files
   in typical web application paths.
3. Target file: `/var/www/html/config/internal.xml`

**WHAT TO SUBMIT**
Flag format: `AETHON{...}` — found in `/etc/flag1.txt` (readable via XXE)

**PIVOT INTEL**
The config file you read will contain credentials for the next machine.
Look for `<host>`, `<username>`, and `<password>` fields.

---
*Next: Use the credentials found here to access aethon-docs on port 5000*
