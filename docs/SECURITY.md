# Zero-Boot Security Guide

## Security Model

Zero-Boot implements a **defense-in-depth** security model with multiple layers of protection.

## Threat Model

### Threats Addressed

1. **Unauthorized Internet Access**
   - Threat: Malicious actors gaining internet access without authorization
   - Mitigation: WAN disabled by default, requires authentication

2. **Network Intrusion**
   - Threat: Attackers moving laterally across network
   - Mitigation: VLAN segmentation isolates network zones

3. **Credential Theft**
   - Threat: Password interception or brute force attacks
   - Mitigation: SHA-256 hashing, no password transmission

4. **Compromised Devices**
   - Threat: Infected devices spreading malware
   - Mitigation: Guest VLAN isolation, quarantine zone

### Threats Not Addressed

This system does NOT protect against:
- Physical access to router
- Firmware vulnerabilities in OpenWrt
- Advanced persistent threats (APTs)
- Zero-day exploits
- Social engineering attacks

## Security Features

### 1. WAN Lockdown

**Implementation**: WAN interface disabled via UCI configuration

```uci
config interface 'wan'
	option disabled '1'
```

**Security Benefits**:
- Prevents unauthorized internet access
- Reduces attack surface
- Limits data exfiltration opportunities

**Limitations**:
- Can be bypassed with physical access
- Requires proper initial configuration
- Does not prevent LAN-based attacks

### 2. Password Hash Authentication

**Implementation**: SHA-256 client-side hashing

```javascript
const hashedPassword = await sha256(password);
```

**Security Benefits**:
- Password never transmitted in plaintext
- Resistant to network sniffing
- One-way function prevents reversal

**Limitations**:
- Hash can be stolen from JavaScript source
- No rate limiting by default
- No multi-factor authentication

**Recommendations**:
1. Use strong, unique passwords (16+ characters)
2. Regularly rotate password hashes
3. Implement rate limiting for production
4. Consider adding TOTP/2FA

### 3. VLAN Segmentation

**Implementation**: Switch VLAN configuration

```
VLAN 1:  Management (trusted)
VLAN 10: Guest (isolated)
VLAN 99: Quarantine (restricted)
```

**Security Benefits**:
- Limits lateral movement
- Isolates compromised devices
- Separates trust zones

**Limitations**:
- Requires VLAN-capable hardware
- Can be bypassed via VLAN hopping attacks
- Misconfiguration can break isolation

**Recommendations**:
1. Use VLAN-aware switches
2. Disable unused ports
3. Enable port security
4. Monitor inter-VLAN traffic

### 4. Audit Logging

**Implementation**: Syslog logging of all unlock attempts

```bash
logger -t zero-boot "WAN unlock attempt..."
```

**Security Benefits**:
- Tracks authentication attempts
- Enables forensic analysis
- Detects brute force attacks

**Limitations**:
- Logs stored on router (limited space)
- Can be cleared by attacker with access
- No alerting mechanism

**Recommendations**:
1. Forward logs to external syslog server
2. Set up log monitoring/alerting
3. Regularly review logs
4. Implement log rotation

## Hardening Recommendations

### Critical (Implement Immediately)

1. **Change Default Password**
   ```bash
   ./deploy.sh --generate-hash "your-secure-password"
   # Update hash in trap-interface.html and unlock-wan.sh
   ```

2. **Disable WAN SSH Access**
   ```bash
   uci set firewall.@rule[0].enabled='0'
   uci commit firewall
   /etc/init.d/firewall restart
   ```

3. **Enable HTTPS**
   ```bash
   opkg update
   opkg install uhttpd-mod-tls
   # Generate SSL certificate
   # Configure uhttpd for HTTPS
   ```

### Important (Implement Soon)

4. **Implement Rate Limiting**
   
   Add to `unlock-wan.sh`:
   ```bash
   # Rate limiting: 3 attempts per 5 minutes
   ATTEMPTS=$(logread | grep -c "zero-boot.*unlock attempt" | tail -n 5)
   if [ "$ATTEMPTS" -gt 3 ]; then
       sleep 30
   fi
   ```

5. **Set Up Remote Logging**
   ```bash
   opkg install rsyslog
   # Configure remote syslog server
   ```

6. **Enable Fail2Ban**
   ```bash
   opkg install fail2ban
   # Configure ban rules for repeated failures
   ```

### Recommended (Nice to Have)

7. **Add TOTP 2FA**
   - Implement time-based OTP
   - Require second factor for unlock

8. **Implement Session Tokens**
   - Generate session token after auth
   - Prevent replay attacks

9. **Add IP Whitelisting**
   - Only allow unlock from specific IPs
   - Reduce attack surface

10. **Enable IDS/IPS**
    ```bash
    opkg install snort
    # Configure intrusion detection
    ```

## Password Guidelines

### Strong Password Requirements

- **Minimum Length**: 16 characters
- **Complexity**: Mix of uppercase, lowercase, numbers, symbols
- **Uniqueness**: Not used anywhere else
- **Randomness**: Use password generator

### Example Strong Passwords

✅ Good:
- `Tr0pic@l_B3@ch!2024$Secure`
- `My#D0g!Spot&2024*Router`
- `P@ssw0rd!IsN0tTh1s$1234`

❌ Bad:
- `password123`
- `admin`
- `unlock123` (default)
- `router`

### Password Generation

```bash
# Generate random password
openssl rand -base64 32

# Generate memorable passphrase
shuf -n 6 /usr/share/dict/words | tr '\n' '-'
```

### Hash Generation

```bash
# Using deploy.sh
./deploy.sh --generate-hash "your-password"

# Using command line
echo -n "your-password" | sha256sum

# Using Python
python3 -c "import hashlib; print(hashlib.sha256(b'your-password').hexdigest())"
```

## Vulnerability Disclosure

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email security details to maintainers
3. Allow 90 days for fix before disclosure
4. Provide:
   - Vulnerability description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (optional)

## Security Audit Checklist

### Pre-Deployment

- [ ] Changed default password
- [ ] Generated strong password hash
- [ ] Reviewed configuration files
- [ ] Tested in isolated environment
- [ ] Created backup of current config

### Post-Deployment

- [ ] Verified WAN is disabled
- [ ] Tested unlock mechanism
- [ ] Confirmed VLAN isolation
- [ ] Checked firewall rules
- [ ] Reviewed logs

### Ongoing Maintenance

- [ ] Weekly log reviews
- [ ] Monthly password rotation
- [ ] Quarterly security audits
- [ ] Keep OpenWrt updated
- [ ] Monitor for unusual activity

## Compliance Considerations

### Data Protection

- No personal data collected
- Password hashes stored locally
- Logs contain only access attempts

### Access Control

- Single-factor authentication (password)
- No role-based access control
- All authenticated users have full access

### Network Security

- Segmentation via VLANs
- Default-deny firewall rules
- Disabled WAN by default

## Incident Response

### Suspected Compromise

1. **Immediate Actions**
   - Disconnect router from internet
   - Change unlock password
   - Review logs for unauthorized access
   - Check connected devices

2. **Investigation**
   - Analyze syslog entries
   - Check UCI configuration changes
   - Review network traffic
   - Identify attack vector

3. **Recovery**
   - Factory reset if needed
   - Redeploy clean configuration
   - Update firmware
   - Change all credentials

4. **Post-Incident**
   - Document findings
   - Update security measures
   - Share lessons learned
   - Improve detection

## References

- OpenWrt Security: https://openwrt.org/docs/guide-user/security
- VLAN Security: https://www.cisco.com/c/en/us/support/docs/lan-switching/8021q/17056-741-4.html
- Password Hashing: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- Network Segmentation: https://www.nist.gov/publications/guide-securing-wireless-local-area-networks-wlans

## Conclusion

Zero-Boot provides a solid foundation for router security through:
- Automatic lockdown
- Authentication requirements
- Network isolation
- Audit logging

However, it should be **part of a comprehensive security strategy**, not the only security measure. Implement additional hardening, keep systems updated, and maintain security awareness.

**Remember**: Security is a journey, not a destination.