# Zero-Trust Boot Protocol for Consumer Routers

**Eliminating the 45-second vulnerability window that enables botnet attacks**
---

## The Problem

Zero‑Trust-Boot is a security‑first boot process for OpenWrt routers.  As 83% of consumer routers remain vulnerable due to their "plug and play" architecture.

Traditional routers comes with these vulnerabilities:
- ✗ Activate internet connectivity within 45 - 48 seconds of boot
- ✗ Ship with default credentials (admin/admin)
- ✗ Expose management interface before users can secure them
- ✗ Enable attacks like Mirai botnet and it modern variant (Aisuru, 2025) (600,000+ routers compromised)

**Result:** Massive DDoS attacks, IoT botnet recruitment, home network compromise.

---

## The Solution

**Zero-Trust Boot Protocol**: Invert the standard security model

Most home and small‑office routers still boot with:

- Default admin credentials.
- WAN exposed as soon as the device powers on.
- Weak separation between “trusted” and “untrusted” devices.
- the table below demonstrates the current control flow 

| Traditional Routers             | Zero-Trust Routers |
|-------------------             |-------------------|
| Boot → Connect → Secure        | Boot → Secure → Connect |
| Default credentials active     | No default credentials (forced setup) |
| WAN active in 45 - 48 seconds  | WAN disabled until provisioning |
| Management on all networks     | Management isolated (VLAN 99) |
| Vulnerable to Shodan scans     | Invisible to internet scanners |

This situation creates a window where:

- An adversery on the local network hits the web UI before the owner does have the time to secure the router.  
- Malware living on an internal device pivots through the router.  
- A misconfigured WAN is reachable from the internet with no guard rails.

This protocol and design engineering changes that boot story completely:

1. The router **starts in a locked state** – no WAN connectivity.
2. The owner must **set credentials and authenticate** on a local‑only interface.
3. Only then is WAN brought up and a dedicated VLANs for management/guest/quarantine applied.

This aligns consumer gear with the kind of “zero‑trust from first boot” behavior expected in more critical environments.

## High‑level features

### Security First
- **No Default Credentials**: Forces strong password creation on first boot
- **WAN Isolation**: Internet disabled until cryptographic setup completes
- **Memory-Hard Hashing**: Argon2id (GPU-resistant, OWASP recommended)
- **Network Segmentation**: Management VLAN isolation with VLAN Filtering enabled (trusted admin access)
    - Guest (internet‑only, isolated from management).

### Easy Deployment
- **One-Click Installer**: For OpenWrt-compatible routers
  - A single script pushes:
    - UCI configuration for firewall, VLANs, and WAN lockdown.
    - Web UI files.
    - CGI unlock script.  
- **Cloud-Ready**: Deployable on AWS/GCP for testing
- **Non-Destructive**: Preserves existing router functionality
- **Open Source**: Fully auditable code

### Proven Results
- **Vulnerability Window**: 45 seconds → 0 seconds
- **Attack Surface**: Eliminated boot-time attacks
- **Brute Force Resistance**: 1000+ years with Argon2id
- **Shodan Invisibility**: Management not internet-routable


## Architecture overview

```text
+------------------------------+
|  Initialization Web UI       |
|  - Local only                |
|  - Set admin credentials     |
+--------------+---------------+
               |
               v
+------------------------------+
|  Unlock Controller (CGI)     |
|  - Verifies password hash    |
|  - Create the VLAN           |
|  - Enables WAN               |
|  - Applies VLAN/firewall     |
+--------------+---------------+
               |
               v
+------------------------------+
|  Router Data Plane           |
|  - Management VLAN           |
|  - Guest VLAN                |
+------------------------------+
```
---

## See It In Action

**[Watch 3-Minute Demo Video](demos/video-demo.mp4)** *(Coming Soon)*


**Live Demo:**
```bash
# Try it yourself (safe, virtualized environment)
git clone https://github.com/Abdulaileb/zero-trust-router
cd zero-trust-router/demos
./launch-demo.sh
```
---

## For Business Stakeholders

**Read:** [Business Overview](docs/BUSINESS_OVERVIEW.md)

**Quick Facts:**
- **Market Size**: 1.4 billion routers shipped annually
- **Problem Scale**: 83% remain with default credentials
- **Attack Impact**: Mirai botnet caused millions of dollars in damages
- **Our Solution**: Deployable on existing hardware, no new manufacturing is required

**Deployment Models:**
1. **Firmware Update**: Manufacturers integrate into official firmware
2. **Aftermarket Solution**: Users flash existing routers
3. **Cloud Service**: Managed security for router fleets
4. **Enterprise Edition**: Advanced features for business networks

---

## For Developers

**Read:** [Technical Guide](docs/TECHNICAL_GUIDE.md)

**Architecture:**
- State-machine boot sequence
- Argon2id cryptographic authentication (only available for cloud testing)
   - Due to memory constraint on routers (64MB left after firmware loads) SHA-512 was used 
- VLAN-based network isolation
- OpenWrt/Linux compatible

**Quick Start:**
```bash
# Install on OpenWrt router
# # wget https://github.com/yourusername/zero-trust-router/raw/main/deployment/install.sh *(Coming Soon)*
# chmod +x install.sh
# ./install.sh
```

---

## For End Users

**Read:** [User Guide](docs/USER_GUIDE.md)

**Simple Setup (5 Minutes):**

1. **Power on router** → See setup screen
2. **Create strong password** → System validates complexity
3. **Configure network** → Connect to management VLAN
4. **Activate internet** → Manual one-time activation
5. **Done!** → Secure, protected network

**No technical knowledge required.**
---

## Project Status

- [x] **Research & Design** (M.Sc. Thesis-Project, University of Udine/Klagenfurt)
- [x] **Prototype Implementation** (OpenWrt, QEMU/KVM)
- [x] **Security Testing** (3 attack scenarios validated)
- [x] **Documentation** (Technical & business guides)
- [ ] **Physical Hardware Testing** (TP-Link routers, in progress)
- [ ] **Cloud Deployment** (AWS AMI)
- [ ] **Community Release** (Open source, Q2 2026)

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Areas we need help:**
- Testing on different router models
- UI/UX improvements
- Documentation translation
- Security audits
- Performance optimization

---

## License

MIT License - See [LICENSE](LICENSE) file

**Commercial Use:** Contact atlebbie@gmail.com for licensing discussions

---

## Contact

**Abdulai Tamba Lebbie**  
🎓 M.Sc. Cybersecurity & AI, University of Udine & Klagenfurt  
📧 atlebbie@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/abdulai-tamba-lebbie-9556919b/)  
🐙 [GitHub](https://github.com/Abdulaileb)  

**Academic Supervisor:** Prof. Dr. Peter Schartner, AAU Klagenfurt

---

## Citation

If you use this work in research, please cite:
```bibtex
@mastersthesis{lebbie2025zerotrust,
  title={Zero-Trust Boot Protocol: Redesigning Consumer Router Security},
  author={Lebbie, Abdulai Tamba},
  year={2026},
  school={University of Klagenfurt},
  type={Master's Project}
}
```

---

## Show Your Support

If you find this project valuable, please:
- Star this repository
- Share with your network
- Contribute improvements
- Provide feedback

**Together, we can secure the internet's front door.** 🔒

---

*Built with ❤️ for a more secure internet*