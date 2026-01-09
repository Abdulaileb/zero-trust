root@OpenWrt:/# cat www_provision/cgi-bin/setup
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

# --- 3. SAVE CONFIG (BUT DO NOT APPLY YET) ---
echo "$USER:$HASH" > /etc/config/zero_trust_credentials
chmod 600 /etc/config/zero_trust_credentials
echo -e "$PASS\n$PASS" | passwd root >/dev/null 2>&1

# Management interface on VLAN 99 (eth1.99)
uci set network.mgmt=interface
uci set network.mgmt.proto='static'
uci set network.mgmt.device='eth0.99'
uci set network.mgmt.ipaddr='192.168.99.1'
uci set network.mgmt.netmask='255.255.255.0'
uci add_list firewall.@zone[0].network='mgmt'

# Move Web Server to new IP + root
uci delete uhttpd.main.listen_http 2>/dev/null
uci add_list uhttpd.main.listen_http='192.168.99.1:80'
uci set uhttpd.main.home='/www'

# Mark as complete
touch /etc/config/zero_trust_complete
chmod 444 /etc/config/zero_trust_complete
uci commit

log_msg "Configuration saved. Sending HTML..."

# --- 4. SEND SUCCESS PAGE ---
cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Setup Complete</title>
<style>
body{font-family:-apple-system,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px;margin:0}
.container{background:#fff;border-radius:16px;padding:40px;max-width:600px;box-shadow:0 20px 60px rgba(0,0,0,.3)}
h1{color:#27ae60;text-align:center;margin-bottom:20px}
.step{background:#f8f9fa;padding:15px;margin:15px 0;border-radius:8px;border-left:4px solid #667eea}
.button{display:block;padding:14px;background:#667eea;color:#fff;text-decoration:none;border-radius:8px;text-align:center;margin-top:20px}
.note{margin-top:20px;font-size:13px;color:#555;text-align:center}
</style>
</head>
<body>
<div class="container">
<h1>✓ Setup Complete!</h1>
<p style="text-align:center;color:#666;">User <strong>$USER</strong> created successfully.</p>

<div class="step">
<strong>Step 1: Network Configuration Changed</strong><br>
Management interface has moved to <strong>VLAN 99</strong> (192.168.99.0/24).
</div>

<div class="step">
<strong>Step 2: Access Management Console</strong><br>
Configure your device with IP <strong>192.168.99.5</strong>, gateway <strong>192.168.99.1</strong> and open:<br>
<strong>http://192.168.99.1</strong>
</div>

<p class="note">
Your current connection to 192.168.2.1 will stop working after this step.<br>
This is expected. Reconfigure to VLAN 99 and reconnect.
</p>

<a href="http://192.168.99.1" class="button" id="continueBtn>
Continue to Console </a>

<p class="note" id="autoNote" style="display:none;">
Trying to open the management console automatically…
</p>

</div>

<script>
  // Auto-redirect after a short delay to give mgmt interface time to come up
  setTimeout(function () {
    var note = document.getElementById('autoNote');
    if (note) note.style.display = 'block';
    window.location.href = 'http://192.168.99.1';
  }, 10000);
</script>

</body>
</html>

EOF

# --- 5. APPLY CHANGES IN BACKGROUND ---
(
    sleep 1
    #/etc/init.d/network reload
    #/etc/init.d/firewall reload
    ifup mgmt
    /etc/init.d/uhttpd restart
) &

#> /dev/null 2>&1 &
exit 0
root@OpenWrt:/#