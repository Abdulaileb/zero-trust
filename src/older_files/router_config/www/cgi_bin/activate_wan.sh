root@OpenWrt:/# cat www/cgi-bin/activate_wan
#!/bin/sh

LOG_FILE="/tmp/zero_trust_wan.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

echo "Content-Type: application/json; charset=utf-8"
echo ""

log "=== WAN activation request received ==="

# Verify trusted state
if [ ! -f "/etc/config/zero_trust_complete" ]; then
    log "ERROR: Activation in untrusted state"
    echo '{"status":"error","reason":"untrusted_state"}'
    exit 1
fi

# Configure WAN interface (eth1)
log "Configuring WAN interface..."
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.device='eth1'
uci set network.wan.disabled='0'
uci commit network

# Send immediate response
echo '{"status":"activating"}'

# Activate in background
(
    log "Background: Bringing up eth1..."
    ip link set eth1 up
    sleep 2
    /etc/init.d/network reload
    sleep 3
    log "Background: WAN activation complete"
) >> "$LOG_FILE" 2>&1 &

log "=== Response sent, activation in background ==="
exit 0
root@OpenWrt:/#
