# Zero-Boot Configuration Guide

## Understanding the Configuration Files

### router-config.uci

This file serves as a **reference configuration** showing the complete desired state of a Zero-Boot secured router. It demonstrates:

- Network interfaces with WAN disabled
- VLAN segmentation setup
- Firewall zones and rules
- DHCP server configuration

#### Usage Options

**Option 1: Automated Deployment (Recommended)**

The `deploy.sh` script automatically applies the critical security settings:
- WAN interface disabled
- WAN6 interface disabled
- LAN-to-WAN forwarding disabled

```bash
./deploy.sh --router-ip 192.168.1.1 --user root
```

**Option 2: Manual Configuration**

For advanced users who want full control:

```bash
# Copy the reference config to router
scp router-config.uci root@192.168.1.1:/tmp/

# SSH to router
ssh root@192.168.1.1

# Apply specific sections manually
# For network settings:
uci set network.wan.disabled='1'
uci set network.wan6.disabled='1'
uci commit network

# For firewall settings:
uci set firewall.@forwarding[0].enabled='0'
uci commit firewall

# Restart services
/etc/init.d/network restart
/etc/init.d/firewall restart
```

**Option 3: Import Full Configuration (Advanced)**

If you understand UCI configuration and want to apply the full reference:

```bash
# Backup current config first!
ssh root@192.168.1.1 "sysupgrade -b /tmp/backup.tar.gz"

# Import configuration (be careful - this may override existing settings)
scp router-config.uci root@192.168.1.1:/tmp/
ssh root@192.168.1.1

# Import in batches by section
# Extract network section
grep -A 100 "^config interface" /tmp/router-config.uci > /tmp/network-section.uci

# Review and apply selectively
cat /tmp/network-section.uci | while read line; do
    echo "$line"  # Review each line
    # Apply manually with uci set commands
done
```

### Security Configuration Best Practices

#### 1. Password Hash Configuration

**Current Setup:**
- Hash stored in `trap-interface.html` (client-side JavaScript)
- Hash stored in `unlock-wan.sh` (server-side shell script)

**Security Considerations:**

⚠️ **Client-Side Hash Visibility**: The password hash is visible in the browser's source code. While the actual password is protected by SHA-256 hashing, an attacker with the hash could potentially use it directly.

**Recommended Hardening:**

```bash
# 1. Use strong, unique passwords
./deploy.sh --generate-hash "$(openssl rand -base64 32)"

# 2. Restrict file permissions on the router
ssh root@192.168.1.1 "chmod 600 /www/cgi-bin/unlock-wan.sh"

# 3. Set up IP whitelisting (optional)
ssh root@192.168.1.1 << 'EOF'
# Only allow unlock from specific IP
uci add firewall rule
uci set firewall.@rule[-1].name='Allow unlock from admin IP'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].src_ip='192.168.1.100'
uci set firewall.@rule[-1].dest_port='80'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart
EOF

# 4. Enable HTTPS (see EXAMPLES.md for full instructions)
```

#### 2. Alternative Password Storage Methods

**Method 1: Environment Variables**

Modify `unlock-wan.sh` to read from environment:

```bash
# In /etc/profile or /etc/rc.local
export ZERO_BOOT_HASH="c2a246816867ccd2d5729dec3dc2db634b6a67db069aca843964899b684ee797"

# In unlock-wan.sh
VALID_HASH="${ZERO_BOOT_HASH:-c2a246816867ccd2d5729dec3dc2db634b6a67db069aca843964899b684ee797}"
```

**Method 2: Separate Configuration File**

```bash
# Create secure config file
ssh root@192.168.1.1 << 'EOF'
cat > /etc/zero-boot.conf << 'CONF'
VALID_HASH="c2a246816867ccd2d5729dec3dc2db634b6a67db069aca843964899b684ee797"
CONF
chmod 600 /etc/zero-boot.conf
EOF

# Modify unlock-wan.sh to source it
# Add at the top of unlock-wan.sh:
# . /etc/zero-boot.conf
```

**Method 3: UCI Configuration**

```bash
# Store in UCI
ssh root@192.168.1.1 << 'EOF'
uci set system.zero_boot=section
uci set system.zero_boot.hash='c2a246816867ccd2d5729dec3dc2db634b6a67db069aca843964899b684ee797'
uci commit system
EOF

# Modify unlock-wan.sh to read from UCI:
# VALID_HASH=$(uci get system.zero_boot.hash)
```

#### 3. Multi-Factor Authentication

For enhanced security, add a second factor:

**TOTP Integration:**

```bash
# Install oath-toolkit
ssh root@192.168.1.1 "opkg update && opkg install oath-toolkit"

# Generate TOTP secret
SECRET=$(ssh root@192.168.1.1 "head -c 20 /dev/urandom | base32")
echo "TOTP Secret: $SECRET"

# Modify unlock-wan.sh to require TOTP
# Add to the unlock script:
```

```bash
#!/bin/sh
# ... existing code ...

# Verify TOTP token
read -r POST_DATA
HASH=$(echo "$POST_DATA" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)
TOTP=$(echo "$POST_DATA" | grep -o '"totp":"[^"]*"' | cut -d'"' -f4)

# Validate password hash
if [ "$HASH" = "$VALID_HASH" ]; then
    # Also validate TOTP
    if oathtool --totp --base32 "$TOTP_SECRET" | grep -q "^$TOTP$"; then
        # Both factors validated
        # ... unlock WAN ...
    else
        # TOTP validation failed
        logger -t zero-boot "Invalid TOTP provided"
        echo "Status: 403 Forbidden"
    fi
fi
```

#### 4. Rate Limiting

Protect against brute force attacks:

**Method 1: Simple Shell-Based**

Add to `unlock-wan.sh`:

```bash
# Rate limiting: max 3 attempts per 5 minutes
ATTEMPTS=$(logread | grep "zero-boot.*unlock attempt" | grep "$(date +%H:%M | cut -d: -f1)" | wc -l)
if [ "$ATTEMPTS" -gt 3 ]; then
    logger -t zero-boot "Rate limit exceeded, rejecting request"
    echo "Status: 429 Too Many Requests"
    echo "Content-Type: application/json"
    echo ""
    echo '{"status":"error","message":"Too many attempts, try again later"}'
    exit 1
fi
```

**Method 2: iptables-Based**

```bash
# Limit requests to unlock script
iptables -A INPUT -p tcp --dport 80 -m string --string "/cgi-bin/unlock-wan.sh" --algo bm -m recent --name unlock_attempts --set
iptables -A INPUT -p tcp --dport 80 -m string --string "/cgi-bin/unlock-wan.sh" --algo bm -m recent --name unlock_attempts --update --seconds 300 --hitcount 4 -j DROP
```

**Method 3: fail2ban**

```bash
# Install fail2ban
ssh root@192.168.1.1 "opkg update && opkg install fail2ban"

# Create filter
cat > /tmp/zero-boot.conf << 'EOF'
[zero-boot]
enabled = true
filter = zero-boot
logpath = /var/log/messages
maxretry = 3
findtime = 300
bantime = 3600
EOF

# Create filter definition
cat > /tmp/zero-boot-filter.conf << 'EOF'
[Definition]
failregex = zero-boot.*Invalid hash provided
ignoreregex =
EOF

# Deploy to router
scp /tmp/zero-boot.conf root@192.168.1.1:/etc/fail2ban/jail.d/
scp /tmp/zero-boot-filter.conf root@192.168.1.1:/etc/fail2ban/filter.d/zero-boot.conf
ssh root@192.168.1.1 "/etc/init.d/fail2ban restart"
```

### VLAN Configuration

The reference configuration includes three VLANs:

#### VLAN 1 - Management (Default)
- Ports: 0-3, Tagged on 6
- Purpose: Trusted devices and administration
- IP Range: 192.168.1.0/24

#### VLAN 10 - Guest Network
- Ports: 4, Tagged on 6
- Purpose: Guest devices with limited access
- IP Range: Configure separately if needed

#### VLAN 99 - Quarantine
- Ports: Tagged on 6 only
- Purpose: Isolated compromised devices
- No internet access

**Customizing VLANs:**

```bash
# Add IoT VLAN (VLAN 20)
ssh root@192.168.1.1 << 'EOF'
uci add network switch_vlan
uci set network.@switch_vlan[-1].device='switch0'
uci set network.@switch_vlan[-1].vlan='20'
uci set network.@switch_vlan[-1].ports='5 6t'
uci set network.@switch_vlan[-1].description='IoT VLAN'

# Create interface for IoT VLAN
uci set network.iot=interface
uci set network.iot.device='eth0.20'
uci set network.iot.proto='static'
uci set network.iot.ipaddr='192.168.20.1'
uci set network.iot.netmask='255.255.255.0'

uci commit network
/etc/init.d/network restart
EOF
```

### Firewall Configuration

**Default Zones:**
- **lan**: Accept input, accept output, accept forward
- **wan**: Reject input, accept output, reject forward (disabled by default)
- **guest**: Reject input, accept output, reject forward

**Default Forwarding:**
- LAN → WAN: Disabled (locked down)
- Guest → LAN: Blocked
- Guest → WAN: Blocked

**Customizing Rules:**

```bash
# Allow specific service through firewall
ssh root@192.168.1.1 << 'EOF'
# Allow HTTPS from WAN (after unlock)
uci add firewall rule
uci set firewall.@rule[-1].name='Allow HTTPS'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='443'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart
EOF
```

## Configuration Validation

After applying configuration, verify it:

```bash
# Check WAN status
ssh root@192.168.1.1 "uci show network.wan.disabled"
# Should return: 1

# Check firewall forwarding
ssh root@192.168.1.1 "uci show firewall | grep forwarding"

# Check if unlock script is executable
ssh root@192.168.1.1 "ls -l /www/cgi-bin/unlock-wan.sh"
# Should show: -rwxr-xr-x

# Test trap interface
curl -s http://192.168.1.1 | grep "Zero-Boot"
# Should return HTML containing Zero-Boot
```

## Troubleshooting Configuration Issues

### WAN Still Enabled After Deployment

```bash
# Manually disable WAN
ssh root@192.168.1.1 << 'EOF'
uci set network.wan.disabled='1'
uci set network.wan6.disabled='1'
uci commit network
/etc/init.d/network restart
EOF
```

### Forwarding Rule Not Working

```bash
# List all forwarding rules
ssh root@192.168.1.1 "uci show firewall | grep forwarding"

# Delete and recreate
ssh root@192.168.1.1 << 'EOF'
# Find the index of LAN→WAN forwarding
uci delete firewall.@forwarding[0]
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].dest='wan'
uci set firewall.@forwarding[-1].enabled='0'
uci commit firewall
/etc/init.d/firewall restart
EOF
```

### Cannot Access Trap Interface

```bash
# Check uhttpd status
ssh root@192.168.1.1 "/etc/init.d/uhttpd status"

# Restart uhttpd
ssh root@192.168.1.1 "/etc/init.d/uhttpd restart"

# Check if file exists
ssh root@192.168.1.1 "ls -l /www/index.html"
```

## Production Checklist

Before deploying to production:

- [ ] Change default password hash
- [ ] Use strong, unique password (16+ characters)
- [ ] Enable HTTPS if possible
- [ ] Implement rate limiting
- [ ] Set up remote logging
- [ ] Configure backup system
- [ ] Test unlock mechanism
- [ ] Test re-lock mechanism
- [ ] Document emergency access procedures
- [ ] Train authorized users
- [ ] Set up monitoring/alerting
- [ ] Review and restrict SSH access
- [ ] Enable fail2ban or similar IDS
- [ ] Keep OpenWrt firmware updated

## See Also

- [SETUP.md](SETUP.md) - Setup and installation guide
- [SECURITY.md](SECURITY.md) - Security best practices
- [EXAMPLES.md](EXAMPLES.md) - Usage examples
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture
