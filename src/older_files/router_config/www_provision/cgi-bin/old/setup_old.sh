#!/bin/sh

# Zero-Trust Boot Protocol - Setup Handler (v3.1 - Passlib)

log_msg() {
    logger -t "zero_trust_setup" "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /tmp/zero_trust_setup.log
}

urldecode() {
    local str="$1"
    str="$(echo "$str" | sed 's/+/ /g')"
    str="$(echo "$str" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')"
    printf '%b' "$str"
}

echo "Content-type: text/html; charset=utf-8"
echo ""

log_msg "=== Setup handler invoked ==="

if [ -f "/etc/config/zero_trust_complete" ]; then
    log_msg "ERROR: Already provisioned"
    echo "<html><body><h1>Error: Already Configured</h1></body></html>"
    exit 1
fi

if [ -n "$CONTENT_LENGTH" ]; then
    POST_DATA=$(dd bs=1 count=$CONTENT_LENGTH 2>/dev/null)
else
    POST_DATA=$(cat)
fi

RAW_USER=$(echo "$POST_DATA" | sed -n 's/^.*username=\([^&]*\).*$/\1/p')
RAW_PASS=$(echo "$POST_DATA" | sed -n 's/^.*password=\([^&]*\).*$/\1/p')

USER=$(urldecode "$RAW_USER")
PASS=$(urldecode "$RAW_PASS")

log_msg "Username: $USER"

if [ -z "$USER" ] || [ -z "$PASS" ]; then
    log_msg "ERROR: Missing credentials"
    echo "<html><body><h1>Error: Missing Fields</h1></body></html>"
    exit 1
fi

if [ ${#USER} -lt 4 ]; then
    echo "<html><body><h1>Error: Username Too Short</h1></body></html>"
    exit 1
fi

if [ ${#PASS} -lt 8 ]; then
    echo "<html><body><h1>Error: Password Too Short</h1></body></html>"
    exit 1
fi

# --- ARGON2ID HASHING (PASSLIB) ---
log_msg "Hashing password with Argon2id..."

HASH=$(python3 << 'PYEOF'
from passlib.hash import argon2
import sys

try:
    password = """$PASS"""
    hash_result = argon2.using(
        type='id',
        time_cost=3,
        memory_cost=65536,
        parallelism=4,
        salt_size=16
    ).hash(password)
    print(hash_result)
    sys.exit(0)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)

if [ $? -ne 0 ] || [ -z "$HASH" ]; then
    log_msg "CRITICAL: Hashing failed"
    echo "<html><body><h1>Error: Hashing Failed</h1>"
    echo "<p>Run: opkg install python3-passlib</p></body></html>"
    exit 1
fi

log_msg "Hash generated successfully"

echo "$USER:$HASH" > /etc/config/zero_trust_credentials
chmod 600 /etc/config/zero_trust_credentials

echo -e "$PASS\n$PASS" | passwd root >/dev/null 2>&1

uci set network.mgmt=interface
uci set network.mgmt.proto='static'
uci set network.mgmt.device='eth1.99'
uci set network.mgmt.ipaddr='192.168.99.1'
uci set network.mgmt.netmask='255.255.255.0'
uci add_list firewall.@zone[0].network='mgmt'

uci delete uhttpd.main.listen_http 2>/dev/null
uci add_list uhttpd.main.listen_http='192.168.99.1:80'
uci set uhttpd.main.home='/www'

touch /etc/config/zero_trust_complete
chmod 444 /etc/config/zero_trust_complete

uci commit
/etc/init.d/network reload &
sleep 2
/etc/init.d/firewall reload
/etc/init.d/uhttpd restart

log_msg "Setup completed successfully"

# Success page
echo "<!DOCTYPE html><html><head><title>Setup Complete</title>"
echo "<style>body{font-family:sans-serif;background:linear-gradient(135deg,#667eea,#764ba2);min-height:100vh;display:flex;align-items:center;justify-content:center;margin:0}.container{background:#fff;border-radius:16px;padding:40px;max-width:600px;box-shadow:0 20px 60px rgba(0,0,0,.3);text-align:center}h1{color:#27ae60;margin-bottom:20px}.step{background:#f8f9fa;padding:15px;margin:15px 0;border-radius:8px;text-align:left;border-left:4px solid #667eea}.step strong{color:#667eea}a.button{display:inline-block;padding:12px 30px;background:#667eea;color:#fff;text-decoration:none;border-radius:8px;margin-top:20px}</style>"
echo "</head><body><div class='container'>"
echo "<h1>✓ Setup Complete!</h1>"
echo "<p>User <strong>$USER</strong> created successfully.</p>"
echo "<div class='step'><strong>Step 1:</strong> Network Changed<br>Management moved to <strong>VLAN 99</strong> (192.168.99.0/24)</div>"
echo "<div class='step'><strong>Step 2:</strong> Reconfigure Your Device<br>• IP: 192.168.99.5<br>• Gateway: 192.168.99.1<br>• DNS: 192.168.99.1</div>"
echo "<div class='step'><strong>Step 3:</strong> Access Console<br>Navigate to: <strong>http://192.168.99.1</strong></div>"
echo "<a href='http://192.168.99.1' class='button'>Continue to Console</a>"
echo "</div></body></html>"

exit 0