# Zero‑Trust-Boot - Engineering 

Zero‑Trust-Boot is a security‑first boot process for OpenWrt routers.  
On first power‑on, the router **comes up locked**, with WAN completely disabled, and only enables internet access after a deliberate, authenticated action by the owner of the device.

Instead of the usual “router ships wide open, fix it later”, The Zero‑Trust-Boot makes **secure-by-default** the starting point.


## Why this project exists

Most home and small‑office routers still boot with:

- Default admin credentials.
- WAN exposed as soon as the device powers on.
- Weak separation between “trusted” and “untrusted” devices.

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

- **Automatic WAN Lockdown**  
  - WAN is **disabled on every boot** until an unlock event succeeds.  
  - No outbound connectivity and no forwarding from LAN to WAN until then.

- **Initialization / Trap Interface (Web UI)**  
  - Router hosts a local‑only setup page on the local default ip port.  
  - User sets the admin password and submits it once to unlock. 
  - User get redirected to a dedicated management VLAN, with VLAN filtering enabled. 
  - Passwords are handled as hashes, not stored in clear text.

- **Network Segmentation**  
  - VLAN layout for:
    - Management (trusted admin access).
    - Guest (internet‑only, isolated from management).

- **Automated Deployment**  
  - A single script pushes:
    - UCI configuration for firewall, VLANs, and WAN lockdown.
    - Web UI files.
    - CGI unlock script.  
  - Includes basic validation and automatic backups of existing config.

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
|  - Guest VLAN                |       |
+------------------------------+
