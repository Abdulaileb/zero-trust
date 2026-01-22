# Zero-Boot Setup Guide

## Overview

Zero-Boot is a security-focused router configuration system that implements automatic lockdown with WAN disabled by default. This prevents unauthorized internet access until explicitly unlocked through a secure web interface.

## Features

- **🔒 Automatic Lockdown**: Router boots with WAN interface disabled
- **🌐 Trap Interface**: Web-based unlock mechanism with password hash verification
- **🛡️ Network Isolation**: VLAN segmentation for enhanced security
- **🚀 Automated Deployment**: Single script deployment to router

## System Requirements

### Router Requirements
- OpenWrt or LEDE firmware installed
- Minimum 8MB flash memory
- SSH access enabled
- Web server (uhttpd) installed

### Client Requirements
- SSH client (OpenSSH)
- SCP for file transfer
- Bash shell (for deployment script)
- Network connectivity to router

## Quick Start

### 1. Prerequisites

Ensure your router is running OpenWrt/LEDE firmware and you have:
- Router IP address (default: 192.168.1.1)
- SSH access credentials
- Physical connection to router's LAN port

### 2. Clone Repository

```bash
git clone https://github.com/Abdulaileb/zero-boot.git
cd zero-boot
```

### 3. Configure Password (IMPORTANT!)

Before deployment, generate a secure password hash:

```bash
chmod +x deploy.sh
./deploy.sh --generate-hash "your-secure-password"
```

Update the password hash in both files:
- `trap-interface.html` (line with `VALID_PASSWORD_HASH`)
- `unlock-wan.sh` (line with `VALID_HASH`)

### 4. Deploy to Router

```bash
./deploy.sh --router-ip 192.168.1.1 --user root
```

Or using environment variables:

```bash
export ROUTER_IP=192.168.1.1
export ROUTER_USER=root
./deploy.sh
```

### 5. Access Trap Interface

1. Open browser to `http://192.168.1.1`
2. Enter your unlock password
3. WAN interface will be enabled upon successful authentication

## Configuration Files

### router-config.uci

UCI configuration file that defines:
- Network interfaces (WAN disabled by default)
- VLAN segmentation (Management, Guest, Quarantine)
- Firewall rules with zone isolation
- DHCP server settings

### trap-interface.html

Web-based unlock interface featuring:
- Modern, responsive design
- Client-side SHA-256 password hashing
- Real-time authentication feedback
- Automatic redirect after unlock

### unlock-wan.sh

CGI script that:
- Validates password hash
- Enables WAN interface via UCI
- Restarts network services
- Logs all unlock attempts

### deploy.sh

Automated deployment script that:
- Validates prerequisites
- Tests router connectivity
- Creates configuration backup
- Deploys all files
- Applies configuration

## Network Architecture

### VLAN Configuration

```
VLAN 1  - Management (Ports 0-3, Tagged on 6)
VLAN 10 - Guest Network (Port 4, Tagged on 6)
VLAN 99 - Quarantine (Tagged on 6)
```

### IP Addressing

```
LAN:  192.168.1.1/24   (Management)
WAN:  Disabled         (Security lockdown)
```

### Firewall Zones

```
LAN  → WAN:   Blocked by default
Guest → LAN:  Blocked
Guest → WAN:  Blocked
```

## Security Features

### 1. Automatic Lockdown
- WAN interface disabled on boot
- Prevents unauthorized internet access
- Requires explicit unlock action

### 2. Password Hash Verification
- SHA-256 hashing for passwords
- Client-side hashing (password never transmitted)
- Server-side hash validation

### 3. Network Isolation
- VLAN segmentation prevents lateral movement
- Separate zones for management and guest access
- Quarantine VLAN for compromised devices

### 4. Audit Logging
- All unlock attempts logged via syslog
- Successful/failed authentication tracked
- Review logs with: `logread | grep zero-boot`

## Advanced Usage

### Custom VLAN Configuration

Edit `router-config.uci` to add custom VLANs:

```uci
config switch_vlan
	option device 'switch0'
	option vlan '20'
	option ports '5 6t'
	option description 'Custom VLAN'
```

### Multiple Password Hashes

Modify `unlock-wan.sh` to support multiple authorized passwords:

```bash
VALID_HASH_1="hash1..."
VALID_HASH_2="hash2..."

if [ "$HASH" = "$VALID_HASH_1" ] || [ "$HASH" = "$VALID_HASH_2" ]; then
    # Unlock logic
fi
```

### Temporary Access

Enable WAN for limited time (add to `unlock-wan.sh`):

```bash
# Enable WAN temporarily (1 hour)
at now + 1 hour << 'ATEOF'
uci set network.wan.disabled='1'
uci commit network
/etc/init.d/network restart
ATEOF
```

## Troubleshooting

### Cannot Access Router

**Problem**: Cannot reach router at IP address

**Solutions**:
1. Verify physical connection to LAN port
2. Check router IP with `ip addr show`
3. Try default gateway: `route -n`
4. Reset router to factory defaults if needed

### Deployment Fails

**Problem**: Deployment script fails to copy files

**Solutions**:
1. Verify SSH access: `ssh root@192.168.1.1`
2. Check router has enough space: `df -h`
3. Ensure uhttpd is running: `/etc/init.d/uhttpd status`
4. Review deployment logs

### Password Not Working

**Problem**: Correct password rejected

**Solutions**:
1. Verify password hash matches in both files
2. Check browser console for errors (F12)
3. Review router logs: `logread | grep zero-boot`
4. Ensure CGI script is executable

### WAN Not Enabling

**Problem**: Authentication succeeds but WAN remains disabled

**Solutions**:
1. Check UCI configuration: `uci show network.wan`
2. Verify firewall rules: `uci show firewall`
3. Manually enable: `uci set network.wan.disabled='0' && uci commit`
4. Restart network: `/etc/init.d/network restart`

## Security Best Practices

1. **Change Default Password**: Never use the default "unlock123" password
2. **Use Strong Passwords**: Minimum 16 characters with mixed case, numbers, symbols
3. **Regular Updates**: Keep OpenWrt firmware updated
4. **Monitor Logs**: Review unlock attempts regularly
5. **Backup Configuration**: Keep secure backups of your configuration
6. **Limit SSH Access**: Disable WAN SSH access when not needed
7. **Enable HTTPS**: Use HTTPS for trap interface in production

## Backup and Recovery

### Create Backup

```bash
# Manual backup
ssh root@192.168.1.1 "sysupgrade -b /tmp/backup.tar.gz"
scp root@192.168.1.1:/tmp/backup.tar.gz ./backup-$(date +%Y%m%d).tar.gz
```

### Restore Backup

```bash
scp backup-YYYYMMDD.tar.gz root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "sysupgrade -r /tmp/backup-YYYYMMDD.tar.gz"
```

### Factory Reset

If locked out:
1. Press and hold reset button for 10+ seconds
2. Router will reset to factory defaults
3. Redeploy Zero-Boot configuration

## API Reference

### POST /cgi-bin/unlock-wan.sh

Unlocks WAN interface with valid password hash.

**Request**:
```json
{
  "hash": "6b89d6b85dcb29a19e8e45f5e1c3d45a..."
}
```

**Response (Success)**:
```json
{
  "status": "success",
  "message": "WAN interface unlocked"
}
```

**Response (Error)**:
```json
{
  "status": "error",
  "message": "Invalid authentication"
}
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

See LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/Abdulaileb/zero-boot/issues
- Documentation: https://github.com/Abdulaileb/zero-boot/wiki

## Changelog

### Version 1.0.0 (Initial Release)
- Automatic WAN lockdown on boot
- Web-based trap interface with password authentication
- VLAN segmentation for network isolation
- Automated deployment script
- Comprehensive documentation
