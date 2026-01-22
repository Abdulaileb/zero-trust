#!/bin/sh

# --- LOGGING & HELPERS ---
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

# --- 1. PARSE INPUT ---
if [ -f "/etc/config/zero_trust_complete" ]; then
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

if [ -z "$USER" ] || [ -z "$PASS" ]; then
    echo "<html><body><h1>Error: Missing Fields</h1></body></html>"
    exit 1
fi

# --- 2. HASHING ---
log_msg "Hashing password..."
HASH=$(python3 << 'PYEOF'
from passlib.hash import argon2
import sys
try:
    password = """$PASS"""
    hash_result = argon2.using(
        type='id',
        time_cost=2,
        memory_cost=16384,
        parallelism=2,
        salt_size=16
    ).hash(password)
    print(hash_result)
except Exception:
    sys.exit(1)
PYEOF
)

if [ -z "$HASH" ]; then
    echo "<html><body><h1>Error: Hashing Failed</h1></body></html>"
    exit 1
fi

# --- 3. SAVE CONFIG ---
# Save credentials and update root password
echo "$USER:$HASH" > /etc/config/zero_trust_credentials
chmod 600 /etc/config/zero_trust_credentials
echo -e "$PASS\n$PASS" | passwd root >/dev/null 2>&1

# --- 4. VM NETWORK CONFIGURATION ---
log_msg "Configuring Management VLAN for VM environment..."

# Define the Management interface on VLAN 99
# In a VM environment, we use eth0.99 or eth1.99
uci set network.mgmt=interface
uci set network.mgmt.proto='static'
uci set network.mgmt.device='eth0.99'
uci set network.mgmt.ipaddr='192.168.99.1'
uci set network.mgmt.netmask='255.255.255.0'

# Update Firewall to allow access to the management network
uci add_list firewall.@zone[0].network='mgmt'

# Restrict Web Server to only listen on the Management IP
uci delete uhttpd.main.listen_http 2>/dev/null
uci add_list uhttpd.main.listen_http='192.168.99.1:80'
uci set uhttpd.main.home='/www'

# Mark setup as complete and commit UCI changes
touch /etc/config/zero_trust_complete
chmod 444 /etc/config/zero_trust_complete
uci commit

log_msg "Configuration saved. Sending HTML..."

# --- 5. SEND SUCCESS PAGE ---
cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Setup Complete</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
    background: linear-gradient(135deg, #6366f1 0%, #7c3aed 100%);
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
  }
  .card {
    background: #ffffff;
    border-radius: 16px;
    padding: 30px 34px 24px;
    max-width: 640px;
    width: 100%;
    box-shadow: 0 20px 60px rgba(15, 23, 42, 0.35);
  }
  h1 { color: #16a34a; text-align: center; margin-bottom: 6px; font-size: 22px; }
  .subtitle { text-align: center; font-size: 14px; color: #4b5563; margin-bottom: 16px; }
  .step {
    background: #f9fafb;
    padding: 12px 14px;
    margin-top: 10px;
    border-radius: 8px;
    border-left: 4px solid #6366f1;
    font-size: 13px;
    color: #111827;
  }
  .step strong { display: block; margin-bottom: 4px; }
  .note { margin-top: 14px; font-size: 12px; color: #6b7280; text-align: center; line-height: 1.4; }
  .timer { margin-top: 6px; font-size: 12px; color: #374151; text-align: center; }
  .button {
    display: block;
    margin: 16px auto 0;
    padding: 10px 20px;
    max-width: 260px;
    text-align: center;
    background: #6366f1;
    color: #ffffff;
    text-decoration: none;
    border-radius: 999px;
    font-size: 14px;
    font-weight: 500;
  }
</style>
</head>
<body>
  <div class="card">
    <h1>✓ Setup complete</h1>
    <p class="subtitle">User <strong>$USER</strong> created. Zero-trust profile active.</p>
    <div class="step">
      <strong>Step 1 · Network configuration changed</strong>
      Management access moved to <strong>VLAN 99</strong> (192.168.99.1).
    </div>
    <div class="step">
      <strong>Step 2 · Access the management console</strong>
      Set your device IP to <strong>192.168.99.5</strong> and open: <strong>http://192.168.99.1</stron>
    </div>
    <p class="note">Current connection to 192.168.2.1 will drop. Reconnect via VLAN 99.</p>
    <p class="timer">Redirecting in <span id="countdown">10</span> seconds…</p>
    <a href="http://192.168.99.1" class="button">Go to console now</a>
  </div>
<script>
  (function () {
    var remaining = 10;
    var span = document.getElementById('countdown');
    function tick () {
      remaining--;
      if (span) span.textContent = remaining;
      if (remaining <= 0) { window.location.href = 'http://192.168.99.1'; return; }
      setTimeout(tick, 1000);
    }
    tick();
  })();
</script>
</body>
</html>
EOF

# --- 6. APPLY CHANGES IN BACKGROUND ---
(
    sleep 2
    # Reload network logic specifically for VM interfaces
    ifup mgmt
    /etc/init.d/uhttpd restart
) &

exit 0
