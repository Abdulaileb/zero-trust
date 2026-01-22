root@OpenWrt:/# cat www/cgi-bin/deactivate_wan
#!/bin/sh

LOG_FILE="/tmp/zero_trust_wan.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

echo "Content-Type: application/json; charset=utf-8"
echo ""

log "=== WAN deactivation request received ==="

# Verify trusted state
if [ ! -f "/etc/config/zero_trust_complete" ]; then
    log "ERROR: Deactivation in untrusted state"
    echo '{"status":"error","reason":"untrusted_state"}'
    exit 1
fi

# Mark WAN disabled in config
log "Disabling WAN interface in UCI..."
uci set network.wan.disabled='1'
uci commit network

# Immediate response so UI does not hang
echo '{"status":"deactivating"}'

# Background shutdown
(
    log "Background: ifdown wan..."
    /sbin/ifdown wan 2>>"$LOG_FILE"
    ip link set eth1 down 2>>"$LOG_FILE"
    log "Background: WAN deactivation complete"
) &

log "=== Response sent, deactivation in background ==="
exit 0
root@OpenWrt:/#
