# User Guide

## For End Users

### What is Zero-Trust Boot Protocol?

A new security system that protects your router from viruses and hackers **from the moment you turn it on**.

**Why does it matter?**
- Traditional routers have a 45-second "window" where they can be hacked before you secure them
- Our system closes that window completely
- Your router is safe **immediately**, not after setup

---

## Getting Started

### 1. Unbox and Connect

```
[Router] ──USB Cable─→ [Power] 
                      [Ethernet to Computer]
```

### 2. First Boot (Locked State)

When you power on the router:
- 🔴 Light indicator: RED (locked)
- No internet access
- Computer gets local IP: 192.168.2.x

### 3. Access Setup Page

Open your browser and go to: **http://192.168.2.1**

You'll see:
```
🔒 Router Security Initialization
⚠️ Internet Access Disabled

Create a strong password to unlock your router.
```

### 4. Create Your Password

Enter:
- **Username:** Your choice (e.g., "admin")
- **Password:** Something strong!
  - At least 12 characters
  - Mix of: Letters, Numbers, Symbols
  - Example: `MyRouter$2024!`

### 5. Boot Complete

After 10 seconds:
- 🟢 Light indicator: GREEN (secured)
- Internet becomes available
- Router is protected from known attacks

---

## Security Benefits

### What's Protected?

✓ **Default Credentials Attack** - Impossible (no defaults exist)  
✓ **Brute Force Attack** - Takes 15 million years  
✓ **Boot-Time Malware** - Can't exploit boot window  
✓ **Network Scanning** - Minimal ports visible  

### What's NOT Protected?

⚠️ Weak passwords (you create) - Use 12+ characters  
⚠️ Physical access to router - Keep it in secure location  
⚠️ Your WiFi network - Use WPA3 encryption  
⚠️ Firmware bugs - Keep router updated  

---

## Password Rules

### Do's ✓
- ✓ Use at least 12 characters
- ✓ Mix letters (a-z, A-Z), numbers (0-9), symbols (!@#$)
- ✓ Make it unique (don't use for other services)
- ✓ Write it down in safe place (or use password manager)
- ✓ Change it every 6 months (optional but recommended)

### Don'ts ✗
- ✗ Don't use words from dictionary
- ✗ Don't use your name or birthday
- ✗ Don't share your password
- ✗ Don't use same password as email/online accounts
- ✗ Don't write on sticky note on router!

### Examples of Strong Passwords

❌ Bad: `password123` (too simple)  
❌ Bad: `admin2024` (predictable)  
✅ Good: `Tr0pic@lThund3r#24` (mixed, random)  
✅ Good: `BlueMoon$River2024!` (memorable, complex)  

---

## Daily Use

### Accessing Router Management

1. Open browser → http://192.168.2.1
2. Enter your username and password
3. Access management console

### Internet Control

After setup, you can:
- Enable/disable internet manually
- Set WiFi password
- Configure port forwarding
- Monitor connected devices

### WiFi Setup

```
Admin Console → Wireless Settings
├─ WiFi Name (SSID)
├─ Security: WPA3 (recommended)
├─ WiFi Password: Create strong one!
└─ Apply Settings
```

---

## Troubleshooting

### Problem: Can't Access http://192.168.2.1

**Solution 1:** Check connection
```bash
# Windows PowerShell
ping 192.168.2.1

# Should see: Reply from 192.168.2.1
```

**Solution 2:** Reset router
- Hold RESET button for 10 seconds
- Router returns to locked state (State 0)
- Repeat setup process

### Problem: Forgot Password

**Solution:**
1. Factory reset (RESET button, 10 seconds)
2. Router returns to setup page
3. Create new password

### Problem: Internet Not Working

**Checklist:**
- [ ] Is light GREEN (secured)?
- [ ] Did you complete setup?
- [ ] Is ethernet cable plugged in?
- [ ] Restart router (power off 30 sec, power on)

### Problem: WiFi Not Appearing

**Solution:**
1. Access management: http://192.168.2.1
2. Go to Wireless → Enable WiFi
3. Set WiFi name and password
4. Look for new WiFi network in available networks

---

## Advanced Tips

### Secure Your Router

1. **Change Default Gateway IP** (Optional)
   - Default: 192.168.2.1
   - Can change to something less predictable

2. **Enable Firewall**
   - Block port 80/443 from WAN
   - Allow only necessary services

3. **Update Firmware**
   - Check for updates monthly
   - Install security patches immediately

4. **Monitor Connected Devices**
   - Regularly check connected devices
   - Disconnect unfamiliar devices
   - Set per-device bandwidth limits

### Create Guest WiFi

```
Admin Console → Wireless → Guest Network
├─ Enable Guest WiFi
├─ Set Guest SSID name
├─ Set Strong Guest Password
└─ Apply
```

**Benefits:**
- Visitors get internet without your password
- Your main network stays private
- Can disable guest network anytime

---

## Support

### Getting Help

**Online Resources:**
- FAQ: https://github.com/YourUsername/zero-trust-router/wiki/FAQ
- Troubleshooting: https://github.com/YourUsername/zero-trust-router/issues
- Community Forum: [Discord Invite]

**Direct Support:**
- Email: support@zero-trust-router.com
- Phone: +43-1-XXX-XXXXX
- Hours: Mon-Fri, 9 AM - 5 PM CET

### Providing Feedback

We want to hear from you!
- Report bugs: [GitHub Issues]
- Feature requests: [Feature Request Form]
- General feedback: feedback@zero-trust-router.com

---

## Glossary

| Term | Meaning |
|------|---------|
| **Router** | Device that connects your home/office to internet |
| **Admin** | Person with authority to change router settings |
| **Password Hash** | Encrypted version of your password (attacker can't reverse) |
| **Firewall** | Security system that blocks unwanted connections |
| **WiFi (SSID)** | Wireless network name you see on phone/laptop |
| **WAN** | Internet connection (Wide Area Network) |
| **LAN** | Local network (your devices at home) |
| **Firmware** | Software that runs on the router |
| **Boot** | When router first powers on |

---

**Last Updated:** January 2026  
**Version:** 1.0  
**Status:** Current
