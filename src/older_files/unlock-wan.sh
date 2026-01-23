#!/bin/sh
# Zero-Boot WAN Unlock Script
# This script enables the WAN interface after successful authentication

# Read JSON input from POST request
read -r POST_DATA

# Extract hash from JSON (simple parsing)
HASH=$(echo "$POST_DATA" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)

# Valid password hash (SHA-256)
# Default password: "unlock123" - CHANGE THIS IN PRODUCTION
VALID_HASH="c2a246816867ccd2d5729dec3dc2db634b6a67db069aca843964899b684ee797"

# Log unlock attempt
logger -t zero-boot "WAN unlock attempt with hash: ${HASH:0:16}..."

# Verify hash
if [ "$HASH" = "$VALID_HASH" ]; then
    logger -t zero-boot "Valid hash provided, unlocking WAN interface"
    
    # Enable WAN interface
    uci set network.wan.disabled='0'
    uci set network.wan6.disabled='0'
    
    # Enable forwarding from LAN to WAN (find the correct rule)
    # Try to find the LAN to WAN forwarding rule
    FORWARD_INDEX=$(uci show firewall | grep "forwarding\[" | grep -m1 "src='lan'" | sed -n "s/.*forwarding\[\([0-9]*\)\].*/\1/p")
    if [ -n "$FORWARD_INDEX" ]; then
        uci set firewall.@forwarding[$FORWARD_INDEX].enabled='1'
    else
        # If no forwarding rule exists, create one
        uci add firewall forwarding
        uci set firewall.@forwarding[-1].src='lan'
        uci set firewall.@forwarding[-1].dest='wan'
        uci set firewall.@forwarding[-1].enabled='1'
    fi
    
    # Commit changes
    uci commit network
    uci commit firewall
    
    # Restart network and firewall services
    /etc/init.d/network restart
    /etc/init.d/firewall restart
    
    # Log success
    logger -t zero-boot "WAN interface successfully unlocked"
    
    # Return success response
    echo "Content-Type: application/json"
    echo ""
    echo '{"status":"success","message":"WAN interface unlocked"}'
    
else
    logger -t zero-boot "Invalid hash provided, access denied"
    
    # Return error response
    echo "Status: 403 Forbidden"
    echo "Content-Type: application/json"
    echo ""
    echo '{"status":"error","message":"Invalid authentication"}'
fi
