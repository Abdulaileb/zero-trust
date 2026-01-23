root@OpenWrt:/# cat www/cgi-bin/custom_reset
#!/bin/sh

LOG_FILE="/tmp/zero_trust_factory_reset.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

echo "Content-Type: text/html; charset=utf-8"
echo ""

log "=== Factory reset requested from web UI ==="

# 1. Remove zero-trust markers and credentials (be tolerant)
log "Removing zero-trust state files..."
rm -f /etc/config/zero_trust_complete
rm -f /etc/config/zero_trust_credentials

# 2. Remove dedicated management interface
log "Deleting mgmt interface from UCI..."
uci delete network.mgmt 2>/dev/null || true
uci commit network

# 3. Restore uHTTPd to listen on all addresses, default docroot
log "Resetting uHTTPd listeners..."
uci delete uhttpd.main.listen_http 2>/dev/null || true
uci delete uhttpd.main.listen_https 2>/dev/null || true

uci add_list uhttpd.main.listen_http='0.0.0.0:80'
uci add_list uhttpd.main.listen_https='0.0.0.0:443'
uci set uhttpd.main.home='/www_provision'
uci commit uhttpd

# 4. Apply changes in background to avoid browser hang
(
    log "Restarting network and uhttpd..."
    /etc/init.d/network restart
    /etc/init.d/uhttpd restart
    log "Factory reset sequence complete."
) >/dev/null 2>&1 &

# 5. Show a friendly confirmation page
cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Factory Reset</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
body{font-family:-apple-system,system-ui,sans-serif;background:linear-gradient(135deg,#f97373,#fb923c);min-height:100vh;display:flex;align-items:center;justify-content:center;margin:0;padding:20px}
.card{background:#fff;border-radius:16px;max-width:520px;width:100%;padding:32px;box-shadow:0 18px 45px rgba(0,0,0,.25)}
h1{margin:0 0 12px;font-size:22px;color:#b91c1c}
p{margin:6px 0;color:#4b5563;font-size:14px}
.step{margin-top:18px;padding:12px 14px;border-radius:8px;background:#f9fafb;border-left:4px solid #f97316;font-size:13px}
.btn{display:inline-block;margin-top:22px;padding:10px 20px;border-radius:8px;background:#111827;color:#fff;text-decoration:none;font-size:14px;font-weight:500}
.small{margin-top:12px;font-size:12px;color:#6b7280}
</style>
</head>
<body>
<div class="card">
  <h1>Device reset in progress</h1>
  <p>Zero-trust state and custom management interface are being cleared.</p>
  <div class="step">
    <strong>What happens now?</strong><br>
    - Zero-trust flags and credentials are removed.<br>
    - The dedicated management VLAN is detached from the UI.<br>
    - The web interface returns to the initial setup page.
  </div>
  <div class="step">
    <strong>How to reconnect</strong><br>
    After 10–15 seconds, reload your browser and open:<br>
    <strong>http://192.168.2.1</strong> (or your default LAN IP).
  </div>
  <a href="http://192.168.2.1" class="btn">Return to initialization →</a>
  <p class="small">
    Your current session may drop while the network and web server restart. This is expected behavior.
  </p>
</div>
</body>
</html>
EOF

exit 0

root@OpenWrt:/#
