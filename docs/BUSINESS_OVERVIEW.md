# Zero-Trust Router - Business Overview
*For Non-Technical Stakeholders*

---
## Executive Summary

**The Zero-Trust Boot Protocol eliminates a critical security gap in consumer and SME routers, affecting 83% of these routers, preventing botnet attacks and network compromise: the insecure window between power-on and full protection..**

**Market Opportunity:**
- 1.4 billion routers shipped annually
- Persistent botnet threats exploiting early-boot exposure
- Regulatory momentum around IoT and router security (EU CRA, NIS2)
- No existing solution addresses the boot-time attack surface

**Value Proposition:**
- Deployable on existing hardware (OpenWrt-class routers)
- Reduces attack surface from 45+ seconds to zero
- Open-source foundation for trust, auditability, and adoption
---

## The Problem 

### What's Wrong Today?

**Imagine buying a house where:**
- The front door is wide open for 45 - 48 seconds after you moved in
- The key is "admin/admin" and everyone knows it
- Burglars drive by scanning for open doors
- 83% of homeowners never change the locks, beacuse they are never actively tasked for that

Even with randomized passwords and onboarding apps, routers still boot into an insecure state:

- Management interfaces are often exposed before credentials are enforced
- Services like SSH, Telnet, or TR-069 may be active before lockdown
- Attackers exploit this brief window to inject malware or hijack devices
- Once compromised, routers become persistent entry points into SME networks

**Real-World Impact**
- Modern botnets (e.g. Mozi, Mirai variants) now exploit boot-time exposure, not just default credentials
- Shodan and Censys still index hundreds of thousands of routers with exposed admin ports and weak configurations
- IoT growth (29.4B devices by 2030) increases the attack surface
- SMEs and industrial sites are especially vulnerable due to legacy hardware and limited IT support


**That's exactly how consumer routers work.**

### Real-World Impact

**Why This Problem Persists:**
- Boot-time is a blind spot — security controls activate after the system is already exposed
- Vendors prioritize usability over secure defaults
- No incentives or mandates to fix early-stage exposure
- Legacy routers remain widely deployed, especially in SMEs and industrial networks

### Why Haven't Manufacturers Fixed This?

1. **Backwards Compatibility**: Changing boot behavior breaks existing tools
2. **Support Costs**: Strong password requirements = more support calls
3. **Marketing**: "Plug and Play" sells better than "Secure First"
4. **No Regulation**: Nobody forces them to fix it

**This is where we come in.**

---

## The Solution (What We Built)

| Traditional Routers                | Zero-Trust Routers |
|-------------------                 |-------------------|
| Boots into open state              | Boots into isolated, locked-down state |
| Admin interface exposed on LAN     | Admin VLAN isolated until cryptographic unlock |
| Services start before auth         | Services gated by sealed credentials |
| Assumes local network is safe      | Assumes nothing is safe until verified |

### Core Innovation
- Cryptographic boot chain with sealed credentials (Argon2id)
- Management VLAN isolation — admin interface is invisible to untrusted clients
- No WAN exposure until trust is established
- Modular design for integration with existing OpenWrt-based routers
- Future-ready: TinyML anomaly detection and secure logging pipeline in roadmap

**We inverted the security model:**
- Protects SMEs and industrial networks from botnets, lateral movement, and remote exploits
- Enables secure provisioning without relying on vendor cloud or insecure defaults
- Supports EU regulatory goals (Cyber Resilience Act, NIS2)
- Builds trust through transparency — open-source, auditable, and community-driven

**Traditional Router:**
Power On → Connect to Internet → User secures (maybe)
↑
45-second vulnerability window

**Zero-Trust Router:**
Power On → User creates strong password → Connect to Internet
↑
Zero vulnerability window


### How It Works (Non-Technical)

**Step 1: Power On**
- Router boots but doesn't connect to internet
- User sees setup screen (not admin login)

**Step 2: First-Time Setup**
- User creates strong password (system enforces complexity)
- Password is encrypted using military-grade hashing
- No default "admin/admin" credentials exist

**Step 3: Network Isolation**
- Management interface moves to separate, isolated network
- Internet scanners can't find router (invisible to Shodan)

**Step 4: Manual Activation**
- User manually activates internet connection
- Only after everything is secured

**Step 5: Done**
- Router works normally
- But attackers can't exploit boot window
- Default credential attacks fail completely

### Security Benefits

| Feature |                  Traditional Router      | Zero-Trust Router |
|---------|                  -------------------     |-------------------|
| Default Credentials        | Yes (known passwords) | No (forced setup) |
| Boot Vulnerability Window  | 45 seconds            | 0 seconds         |
| Shodan Discoverable        | Yes                   | No                |
| Brute Force Attacks        | Possible (MD5/SHA)    | Infeasible (Argon2id) |
| Management Exposure        | All networks          | Isolated VLAN     |
| Factory Reset              | Returns to vulnerable | Requires re-provisioning |

---

## Why Now?

### Perfect Timing

1. **Regulatory Pressure**: New laws mandating IoT security
2. **Market Awareness**: Recent attacks (healthcare, infrastructure)
3. **Technology Readiness**: OpenWrt ecosystem mature
4. **Funding Environment**: Cybersecurity attractive to investors
5. **Team Readiness**: Working prototype + academic validation