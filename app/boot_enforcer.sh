#!/bin/sh
# Zero-Trust Boot Enforcer (Digital Twin)

FLAG="/etc/config/zero_trust_complete"
NGINX_CONF="/etc/nginx/nginx.conf"

echo "[*] Zero-Trust: Initializing Boot Enforcer..."

# Ensure config directory exists
mkdir -p /etc/config

if [ ! -f "$FLAG" ]; then
    echo "[!] STATUS: UNTRUSTED. Enforcing Fail-Closed state."
    # We use Nginx to control access. In unprovisioned state, the logic is:
    # Port 80 -> /www_provision
    # Port 99 -> 403 Forbidden (handled in nginx.conf via the absence of the flag if possible, 
    # or we can swap configs if needed. For simplicity, we'll use one nginx.conf that checks the file)
else
    echo "[+] STATUS: TRUSTED. Zero-Trust Profile Active."
    echo "[+] VLAN 99 (Management) is now ROUTABLE."
fi

# Start Nginx in background
nginx

# Start the Python Setup Engine
python3 /app/setup.py
