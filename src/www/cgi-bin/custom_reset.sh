#!/bin/sh

LOG_FILE="/tmp/zero_trust_factory_reset.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

echo "Content-Type: text/html; charset=utf-8"
echo ""

log "=== Factory reset requested from web UI ==="

# 1. Remove zero-trust markers and credentials
log "Removing zero-trust state files..."
rm -f /etc/config/zero_trust_complete
rm -f /etc/config/zero_trust_credentials

# 2. Redirect back to provisioning
cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>System Reset</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
body{font-family:sans-serif;background:#f3f4f6;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
.card{background:#fff;padding:2rem;border-radius:1rem;box-shadow:0 10px 25px rgba(0,0,0,0.1);text-align:center;max-width:400px}
h1{color:#ef4444;margin-bottom:1rem}
.btn{display:inline-block;margin-top:1rem;padding:0.75rem 1.5rem;background:#3b82f6;color:#fff;text-decoration:none;border-radius:0.5rem}
</style>
</head>
<body>
<div class="card">
  <h1>System Reset</h1>
  <p>The Zero-Trust state has been cleared. Returning to initial provisioning...</p>
  <a href="http://localhost:8080" class="btn">Go to Setup Page</a>
  <script>
    setTimeout(() => { window.location.href = "http://localhost:8080"; }, 3000);
  </script>
</div>
</body>
</html>
EOF

exit 0
