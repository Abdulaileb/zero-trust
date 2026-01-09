# Zero-Boot Examples

This document provides practical examples for using Zero-Boot.

## Example 1: Basic Deployment

Deploy Zero-Boot to a router with default settings:

```bash
# Clone repository
git clone https://github.com/Abdulaileb/zero-boot.git
cd zero-boot

# Make deploy script executable
chmod +x deploy.sh

# Generate password hash
./deploy.sh --generate-hash "MySecurePassword123!"
# Output: a1b2c3d4e5f6... (example hash)

# Edit files to update password hash
# Update VALID_PASSWORD_HASH in trap-interface.html (line ~69)
# Update VALID_HASH in unlock-wan.sh (line ~15)

# Deploy to router
./deploy.sh --router-ip 192.168.1.1 --user root
```

## Example 2: Custom Router IP

Deploy to a router with custom IP address:

```bash
# Router at 10.0.0.1
./deploy.sh --router-ip 10.0.0.1 --user admin
```

## Example 3: Using Environment Variables

Set credentials via environment variables:

```bash
export ROUTER_IP=192.168.1.1
export ROUTER_USER=root
export SSH_PORT=2222

./deploy.sh
```

## Example 4: Generate Multiple Password Hashes

Create hashes for different passwords:

```bash
# For admin user
./deploy.sh --generate-hash "AdminPassword2024!"

# For backup access
./deploy.sh --generate-hash "BackupAccess2024!"

# For temporary guest
./deploy.sh --generate-hash "GuestPass2024!"
```

## Example 5: Manual Configuration

If you prefer manual setup:

```bash
# 1. Connect to router
ssh root@192.168.1.1

# 2. Copy files manually
scp trap-interface.html root@192.168.1.1:/www/index.html
scp unlock-wan.sh root@192.168.1.1:/www/cgi-bin/
scp router-config.uci root@192.168.1.1:/tmp/

# 3. Apply configuration
ssh root@192.168.1.1

# Set permissions
chmod +x /www/cgi-bin/unlock-wan.sh

# Apply UCI configuration (line by line from router-config.uci)
uci set network.wan.disabled='1'
uci set network.wan6.disabled='1'
# ... continue with other settings ...

uci commit
/etc/init.d/network restart
/etc/init.d/firewall restart
```

## Example 6: Custom VLAN Setup

Modify router-config.uci for custom VLAN layout:

```uci
# Add IoT VLAN (VLAN 20) on port 4
config switch_vlan
	option device 'switch0'
	option vlan '20'
	option ports '4 6t'
	option description 'IoT Devices VLAN'

# Create IoT interface
config interface 'iot'
	option device 'eth0.20'
	option proto 'static'
	option ipaddr '192.168.20.1'
	option netmask '255.255.255.0'

# Create IoT firewall zone
config zone
	option name 'iot'
	option input 'REJECT'
	option output 'ACCEPT'
	option forward 'REJECT'
	option network 'iot'

# Block IoT to LAN
config rule
	option name 'Block IoT to LAN'
	option src 'iot'
	option dest 'lan'
	option target 'REJECT'
```

## Example 7: Testing Authentication

Test the unlock mechanism locally:

```bash
# 1. Generate test password hash
TEST_HASH=$(echo -n "TestPassword123" | sha256sum | cut -d' ' -f1)
echo "Test hash: $TEST_HASH"

# 2. Create test request
cat > /tmp/test-request.json << EOF
{"hash":"$TEST_HASH"}
EOF

# 3. Test unlock script (on router)
ssh root@192.168.1.1 "cat /tmp/test-request.json | /www/cgi-bin/unlock-wan.sh"
```

## Example 8: Check Router Status

Verify Zero-Boot configuration:

```bash
# SSH to router
ssh root@192.168.1.1

# Check WAN status
uci show network.wan
# Should show: disabled='1'

# Check firewall forwarding
uci show firewall | grep forwarding

# Check VLAN configuration
uci show network | grep switch

# View unlock logs
logread | grep zero-boot
```

## Example 9: Unlock via Web Interface

Using the web interface:

1. Open browser to `http://192.168.1.1`
2. You'll see the Zero-Boot trap interface
3. Enter your password (e.g., "MySecurePassword123!")
4. Click "Unlock WAN Interface"
5. Wait for success message
6. Automatically redirected to router admin

## Example 10: Unlock via API

Programmatically unlock WAN:

```bash
# Using curl
PASSWORD="MySecurePassword123!"
HASH=$(echo -n "$PASSWORD" | sha256sum | cut -d' ' -f1)

curl -X POST http://192.168.1.1/cgi-bin/unlock-wan.sh \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\"}"
```

```python
# Using Python
import hashlib
import requests
import json

password = "MySecurePassword123!"
hash_obj = hashlib.sha256(password.encode())
password_hash = hash_obj.hexdigest()

response = requests.post(
    'http://192.168.1.1/cgi-bin/unlock-wan.sh',
    json={'hash': password_hash}
)

print(response.json())
```

```javascript
// Using Node.js
const crypto = require('crypto');
const fetch = require('node-fetch');

const password = 'MySecurePassword123!';
const hash = crypto.createHash('sha256').update(password).digest('hex');

fetch('http://192.168.1.1/cgi-bin/unlock-wan.sh', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ hash: hash })
})
.then(res => res.json())
.then(data => console.log(data));
```

## Example 11: Backup and Restore

Create and restore backups:

```bash
# Create backup before deployment
./deploy.sh  # Automatically creates backup in ./backups/

# Manual backup
ssh root@192.168.1.1 "sysupgrade -b /tmp/backup.tar.gz"
scp root@192.168.1.1:/tmp/backup.tar.gz ./my-backup.tar.gz

# Restore from backup
scp ./my-backup.tar.gz root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "sysupgrade -r /tmp/my-backup.tar.gz"
```

## Example 12: Monitoring Unlock Attempts

Monitor authentication attempts:

```bash
# View real-time logs
ssh root@192.168.1.1 "logread -f | grep zero-boot"

# View last 10 unlock attempts
ssh root@192.168.1.1 "logread | grep 'zero-boot.*unlock attempt' | tail -10"

# Count failed attempts today
ssh root@192.168.1.1 "logread | grep 'zero-boot.*Invalid hash' | wc -l"
```

## Example 13: Re-lock WAN Interface

Manually disable WAN again:

```bash
ssh root@192.168.1.1 << 'EOF'
  uci set network.wan.disabled='1'
  uci set network.wan6.disabled='1'
  uci commit network
  /etc/init.d/network restart
EOF
```

## Example 14: Scheduled Auto-Lock

Set up automatic re-locking after 24 hours:

```bash
ssh root@192.168.1.1

# Add cron job
echo "0 2 * * * uci set network.wan.disabled='1' && uci commit && /etc/init.d/network restart" | crontab -

# Verify cron job
crontab -l
```

## Example 15: Multiple Routers Deployment

Deploy to multiple routers:

```bash
#!/bin/bash
# deploy-multi.sh

ROUTERS=(
  "192.168.1.1"
  "192.168.2.1"
  "192.168.3.1"
)

for router in "${ROUTERS[@]}"; do
  echo "Deploying to $router..."
  ./deploy.sh --router-ip "$router" --user root
  echo "Done with $router"
  echo ""
done
```

## Example 16: Docker-based Testing

Test in isolated environment (requires Docker):

```bash
# Create Dockerfile for OpenWrt simulation
cat > Dockerfile << 'EOF'
FROM openwrt/rootfs:latest
RUN opkg update
RUN opkg install uhttpd
COPY trap-interface.html /www/index.html
COPY unlock-wan.sh /www/cgi-bin/
RUN chmod +x /www/cgi-bin/unlock-wan.sh
CMD ["/sbin/init"]
EOF

# Build and run
docker build -t zero-boot-test .
docker run -p 8080:80 zero-boot-test
```

## Example 17: HTTPS Configuration

Enable HTTPS on router:

```bash
ssh root@192.168.1.1

# Install SSL packages
opkg update
opkg install uhttpd-mod-tls px5g-mbedtls

# Generate self-signed certificate
px5g selfsign -newkey rsa:2048 -days 3650 \
  -keyout /etc/uhttpd.key \
  -out /etc/uhttpd.crt \
  -subj '/C=US/ST=State/L=City/O=Organization/CN=192.168.1.1'

# Configure uhttpd for HTTPS
uci set uhttpd.main.listen_https='0.0.0.0:443'
uci set uhttpd.main.cert='/etc/uhttpd.crt'
uci set uhttpd.main.key='/etc/uhttpd.key'
uci commit uhttpd

# Restart uhttpd
/etc/init.d/uhttpd restart

# Access via HTTPS
# https://192.168.1.1
```

## Example 18: Remote Syslog

Forward logs to remote server:

```bash
ssh root@192.168.1.1

# Configure remote logging
uci set system.@system[0].log_ip='192.168.1.100'
uci set system.@system[0].log_port='514'
uci set system.@system[0].log_proto='udp'
uci commit system

# Restart syslog
/etc/init.d/log restart
```

## Example 19: Integration with Home Automation

Example Home Assistant automation:

```yaml
# automation.yaml
- alias: "Unlock Router WAN"
  trigger:
    - platform: time
      at: "06:00:00"
  action:
    - service: rest_command.unlock_router

# configuration.yaml
rest_command:
  unlock_router:
    url: "http://192.168.1.1/cgi-bin/unlock-wan.sh"
    method: POST
    content_type: "application/json"
    payload: '{"hash":"YOUR_PASSWORD_HASH_HERE"}'
```

## Example 20: Verification Script

Create a verification script:

```bash
#!/bin/bash
# verify-zero-boot.sh

ROUTER_IP="${1:-192.168.1.1}"

echo "Verifying Zero-Boot installation on $ROUTER_IP..."

# Check trap interface
if curl -s "http://$ROUTER_IP" | grep -q "Zero-Boot"; then
  echo "✓ Trap interface is active"
else
  echo "✗ Trap interface not found"
fi

# Check WAN status
WAN_STATUS=$(ssh root@$ROUTER_IP "uci get network.wan.disabled")
if [ "$WAN_STATUS" = "1" ]; then
  echo "✓ WAN is locked (disabled)"
else
  echo "✗ WAN is not locked"
fi

# Check unlock script
if ssh root@$ROUTER_IP "[ -x /www/cgi-bin/unlock-wan.sh ]"; then
  echo "✓ Unlock script is executable"
else
  echo "✗ Unlock script not found or not executable"
fi

echo "Verification complete!"
```

## Troubleshooting Examples

### Reset to Factory Settings

```bash
ssh root@192.168.1.1
firstboot -y && reboot
```

### Check File Permissions

```bash
ssh root@192.168.1.1 "ls -la /www/cgi-bin/unlock-wan.sh"
# Should show: -rwxr-xr-x
```

### Manual WAN Enable

```bash
ssh root@192.168.1.1
uci set network.wan.disabled='0'
uci commit network
/etc/init.d/network restart
```

### View Current Configuration

```bash
ssh root@192.168.1.1 "uci export network && uci export firewall"
```

## Notes

- Replace `192.168.1.1` with your router's actual IP address
- Replace `root` with your router's username if different
- Always test in a safe environment before production use
- Keep backups of working configurations
- Change default passwords immediately after deployment

For more information, see:
- [SETUP.md](SETUP.md) - Complete setup guide
- [SECURITY.md](SECURITY.md) - Security best practices
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture
