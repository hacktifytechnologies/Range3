# Challenge 4 — Detect: Unauthorised Redis Access + SSH Key Injection
## Operation Iron Sentinel | Detection Stage 4 of 5
### Machine: aethon-cache | Attack: Redis CONFIG SET Abuse

---

**SCENARIO**
The attacker has discovered the unauthenticated Redis instance from the dev
server config and is using Redis CONFIG SET to write an SSH public key
(MITRE T1021.004).

**YOUR TASK**
1. Run Caldera TTP `b4-redis-rce.yml` to simulate the attack
2. Examine Redis server logs for CONFIG SET commands
3. Verify the unauthorized_keys file was modified

**LOG INVESTIGATION COMMANDS**
```bash
# On aethon-cache — Redis log
tail -f /var/log/redis/redis-server.log

# Filter for CONFIG commands
grep -i "config set\|bgsave\|slaveof" /var/log/redis/redis-server.log

# Check if authorized_keys was modified
ls -la /home/cacheops/.ssh/
cat /home/cacheops/.ssh/authorized_keys

# Network connections to Redis
ss -tnp | grep 6379
```

**KEY IOCs TO IDENTIFY**
- Redis `CONFIG SET dir` command pointing to a home directory `.ssh` path
- Redis `CONFIG SET dbfilename authorized_keys`
- `BGSAVE` command issued from a non-localhost (non-127.0.0.1) client IP
- Modification timestamp on `/home/cacheops/.ssh/authorized_keys`
- Subsequent SSH login from a new key fingerprint

**DETECTION RULE (write your own)**
Alert on: Redis CONFIG SET commands from non-localhost sources, any BGSAVE
following a dir/dbfilename change, changes to SSH authorized_keys files.

**REMEDIATION**
Document the three configuration changes to redis.conf that would prevent
this attack (requirepass, bind 127.0.0.1, protected-mode yes).

**SCORING TASKS**
- [ ] Identify the external Redis client IP from logs
- [ ] Extract the exact CONFIG SET commands used
- [ ] Confirm key injection by examining authorized_keys
- [ ] Write a detection rule
- [ ] Document the 3 redis.conf remediations
