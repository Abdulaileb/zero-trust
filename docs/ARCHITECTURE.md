# Zero-Boot Architecture

## System Overview

Zero-Boot is a security-focused router configuration system built on OpenWrt/LEDE firmware. It implements a defense-in-depth approach with automatic lockdown, authentication, and network segmentation.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Browser                          │
│              (trap-interface.html)                          │
└──────────────────┬──────────────────────────────────────────┘
                   │ HTTP/HTTPS
                   │ SHA-256 Hash
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    OpenWrt Router                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              uhttpd Web Server                        │  │
│  │         (serves trap interface)                       │  │
│  └────────────┬──────────────────────────────────────────┘  │
│               │                                              │
│               ▼                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          unlock-wan.sh (CGI)                          │  │
│  │     - Validates hash                                   │  │
│  │     - Modifies UCI config                             │  │
│  │     - Restarts services                               │  │
│  └────────────┬──────────────────────────────────────────┘  │
│               │                                              │
│               ▼                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              UCI Configuration                        │  │
│  │     - Network interfaces                              │  │
│  │     - VLAN settings                                    │  │
│  │     - Firewall rules                                  │  │
│  └────────────┬──────────────────────────────────────────┘  │
│               │                                              │
│               ▼                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Network Stack                               │  │
│  │     - WAN (disabled → enabled)                        │  │
│  │     - LAN (always active)                             │  │
│  │     - VLANs (segmentation)                            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                   │
                   ▼
          ┌────────────────┐
          │   Internet     │
          │  (WAN Access)  │
          └────────────────┘
```

## Component Architecture

### 1. Trap Interface (trap-interface.html)

**Purpose**: Web-based authentication interface

**Technology Stack**:
- HTML5
- CSS3 (responsive design)
- Vanilla JavaScript
- Web Crypto API (SHA-256)

**Key Functions**:
```javascript
// Password hashing
async function sha256(message)

// Form submission handler
document.getElementById('unlockForm').addEventListener('submit', ...)

// Fetch API for backend communication
fetch('/cgi-bin/unlock-wan.sh', {...})
```

**Data Flow**:
1. User enters password
2. Client-side SHA-256 hashing
3. POST request with hash to CGI script
4. Display success/error message
5. Redirect to admin panel on success

**Security Considerations**:
- Password never sent in plaintext
- Hash visible in JavaScript source
- No rate limiting by default
- HTTPS recommended for production

### 2. Unlock Script (unlock-wan.sh)

**Purpose**: CGI backend for authentication and WAN unlock

**Technology**: Shell script (POSIX compatible)

**Key Operations**:
```bash
# Input parsing
read -r POST_DATA
HASH=$(echo "$POST_DATA" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)

# Hash validation
if [ "$HASH" = "$VALID_HASH" ]; then

# UCI modifications
uci set network.wan.disabled='0'
uci commit network

# Service restart
/etc/init.d/network restart
```

**Data Flow**:
1. Receive POST request with JSON payload
2. Extract hash from JSON
3. Compare with stored hash
4. Enable WAN via UCI if valid
5. Restart network services
6. Return JSON response
7. Log attempt to syslog

**Security Considerations**:
- Hash stored in plain text in script
- No rate limiting
- Requires execute permissions
- Logs all attempts

### 3. Router Configuration (router-config.uci)

**Purpose**: Network and security configuration

**Technology**: UCI (Unified Configuration Interface)

**Configuration Sections**:

#### Network Interfaces
```uci
config interface 'wan'
	option device 'eth1'
	option proto 'static'
	option disabled '1'    # Lockdown
```

#### VLAN Configuration
```uci
config switch_vlan
	option vlan '1'        # Management
	option vlan '10'       # Guest
	option vlan '99'       # Quarantine
```

#### Firewall Rules
```uci
config zone
	option name 'wan'
	option input 'REJECT'
	option forward 'REJECT'
```

**Security Architecture**:
- Default-deny firewall policy
- VLAN isolation
- WAN disabled on boot
- LAN-to-WAN forwarding disabled

### 4. Deployment Script (deploy.sh)

**Purpose**: Automated configuration deployment

**Technology**: Bash script

**Workflow**:
```
1. Check Requirements
   ├─ SSH available
   ├─ SCP available
   └─ Router reachable

2. Test Connection
   ├─ Ping router
   └─ Verify SSH access

3. Backup Configuration
   ├─ Create backup
   └─ Download to local

4. Deploy Files
   ├─ Copy router-config.uci
   ├─ Copy trap-interface.html
   └─ Copy unlock-wan.sh

5. Apply Configuration
   ├─ Set permissions
   ├─ Apply UCI config
   └─ Restart services

6. Verify Deployment
   └─ Show summary
```

**Features**:
- Prerequisite validation
- Automatic backups
- Error handling
- Progress reporting
- Password hash generation

## Data Flow Diagrams

### Authentication Flow

```
User              Browser           Router           UCI/Services
 │                  │                 │                    │
 │  Enter Password  │                 │                    │
 ├─────────────────>│                 │                    │
 │                  │                 │                    │
 │                  │  SHA-256 Hash   │                    │
 │                  │────────┐        │                    │
 │                  │        │        │                    │
 │                  │<───────┘        │                    │
 │                  │                 │                    │
 │                  │  POST /unlock   │                    │
 │                  │────────────────>│                    │
 │                  │                 │                    │
 │                  │                 │  Validate Hash     │
 │                  │                 │─────────┐          │
 │                  │                 │         │          │
 │                  │                 │<────────┘          │
 │                  │                 │                    │
 │                  │                 │   Enable WAN       │
 │                  │                 │───────────────────>│
 │                  │                 │                    │
 │                  │                 │  Restart Network   │
 │                  │                 │───────────────────>│
 │                  │                 │                    │
 │                  │   Success       │                    │
 │                  │<────────────────│                    │
 │                  │                 │                    │
 │   Redirect       │                 │                    │
 │<─────────────────│                 │                    │
```

### Network Packet Flow

```
Device (LAN) → Switch → VLAN Tagging → Router → Firewall → WAN (Locked)
                                                    │
                                                    └─> DROP

After Unlock:

Device (LAN) → Switch → VLAN Tagging → Router → Firewall → WAN → Internet
```

## Network Topology

```
                    Internet
                       │
                       ▼
                   [Modem]
                       │
                       │ WAN (Disabled)
                       ▼
              ┌────────────────┐
              │  Zero-Boot     │
              │  Router        │
              │  192.168.1.1   │
              └────────┬───────┘
                       │
                       │ br-lan
                       ▼
              ┌────────────────┐
              │  Switch        │
              │  (VLAN-aware)  │
              └─┬──┬──┬──┬──┬─┘
                │  │  │  │  │
        ┌───────┘  │  │  │  └──────┐
        │          │  │  │         │
        ▼          ▼  ▼  ▼         ▼
    [Port 0]  [Port 1-3]      [Port 4]
    Management  Trusted        Guest
    VLAN 1      VLAN 1         VLAN 10
```

## State Diagram

```
┌──────────────┐
│   Router     │
│   Boot       │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  WAN Locked  │◄────────┐
│  (Default)   │         │
└──────┬───────┘         │
       │                 │
       │ User Access     │ Invalid
       │ Trap Interface  │ Password
       ▼                 │
┌──────────────┐         │
│  Password    │─────────┘
│  Prompt      │
└──────┬───────┘
       │
       │ Valid Password
       ▼
┌──────────────┐
│  Validate    │
│  Hash        │
└──────┬───────┘
       │
       │ Hash Match
       ▼
┌──────────────┐
│  Enable WAN  │
│  Restart Net │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ WAN Unlocked │
│  (Active)    │
└──────────────┘
```

## File System Layout

```
/
├── etc/
│   ├── config/
│   │   ├── network          # Network interfaces, VLANs
│   │   ├── firewall         # Firewall rules, zones
│   │   └── dhcp             # DHCP server config
│   └── init.d/
│       ├── network          # Network init script
│       └── firewall         # Firewall init script
│
├── www/
│   ├── index.html           # Trap interface (trap-interface.html)
│   └── cgi-bin/
│       └── unlock-wan.sh    # Unlock CGI script
│
└── tmp/
    └── router-config.uci    # Temporary config during deploy
```

## Security Layers

### Layer 1: Physical
- Router hardware
- Switch ports
- Network cables

### Layer 2: Network (Data Link)
- VLAN segmentation
- MAC filtering (optional)
- Port security

### Layer 3: Network (IP)
- IP addressing
- Routing rules
- DHCP isolation

### Layer 4: Transport
- Firewall zones
- Port filtering
- Connection tracking

### Layer 7: Application
- Password authentication
- Web interface
- CGI scripting

## Performance Considerations

### Resource Usage

**Memory**:
- Trap interface: ~8KB HTML/CSS/JS
- UCI config: ~2KB
- Unlock script: ~1.5KB
- Total: ~12KB

**CPU**:
- Minimal overhead
- Hash validation: O(1)
- Network restart: ~2-5 seconds

**Storage**:
- Configuration: ~20KB
- Logs: Variable (log rotation recommended)

### Scalability

**Concurrent Users**:
- uhttpd handles multiple connections
- CGI script processes one at a time
- Consider load balancer for high traffic

**Network Throughput**:
- VLAN overhead: ~1-2%
- No impact on WAN throughput when unlocked

## Integration Points

### External Systems

1. **Syslog Server**
   - Forward authentication logs
   - Centralized monitoring

2. **VPN Server**
   - Can integrate with OpenVPN/WireGuard
   - Provide secure remote unlock

3. **RADIUS Server**
   - External authentication
   - Centralized user management

4. **Monitoring Tools**
   - Grafana for metrics
   - Prometheus for alerting
   - ELK stack for log analysis

### API Endpoints

**POST /cgi-bin/unlock-wan.sh**
- Authenticates and unlocks WAN
- Input: JSON with password hash
- Output: JSON with status

**GET /**
- Serves trap interface
- No authentication required

## Deployment Environments

### Development
- Test router or VM
- Isolated network
- Frequent configuration changes

### Staging
- Production-like environment
- Full testing before production
- Limited access

### Production
- Live consumer routers
- HTTPS enabled
- Strong passwords
- Remote logging

## Technology Stack

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  HTML5, CSS3, JavaScript, Fetch API │
├─────────────────────────────────────┤
│         Application Layer           │
│   Shell Scripts, CGI, UCI Commands  │
├─────────────────────────────────────┤
│          Platform Layer             │
│    OpenWrt/LEDE, uhttpd, busybox   │
├─────────────────────────────────────┤
│          Network Layer              │
│  Linux Kernel, netfilter, tc, VLAN  │
├─────────────────────────────────────┤
│          Hardware Layer             │
│  Router SoC, Switch, Ethernet PHY   │
└─────────────────────────────────────┘
```

## Future Enhancements

### Planned Features
- TOTP/2FA support
- Web interface for configuration
- Mobile app for unlock
- Automatic re-lock timer
- Multi-user support
- API for automation

### Technical Debt
- Add rate limiting
- Implement CSRF protection
- Add session management
- Improve error handling
- Add unit tests

## References

- OpenWrt Architecture: https://openwrt.org/docs/guide-developer/
- UCI System: https://openwrt.org/docs/guide-user/base-system/uci
- uhttpd: https://openwrt.org/docs/guide-user/services/webserver/uhttpd
- netfilter/iptables: https://www.netfilter.org/documentation/

## Conclusion

Zero-Boot implements a layered security architecture that:
- Prevents unauthorized access through WAN lockdown
- Authenticates users via password hash verification
- Isolates network segments with VLANs
- Automates deployment with single script

The architecture is designed to be simple, secure, and maintainable, providing a solid foundation for enhanced router security.