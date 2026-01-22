#!/bin/sh -e
# Zero-Trust Boot Enforcer
# Executes on every boot to enforce security state

FLAG="/etc/config/zero_trust_complete"

if [ ! -f "$FLAG" ]; then
    logger -t zero_trust "Device unprovisioned. Enforcing WAN BLACKOUT."

    # Wait for network subsystem to be ready
    #sleep 5

    ## 1. Disable WAN interface
    # Multiple approaches for reliability

    #ifdown wan
    ip link set eth1 down


   # Disable auto-start for WAN.. and enable it logically
    #uci set network.wan.auto='0'
    #uci commit network
    #/etc/init.d/network restart

    ## 2. Force Web Server to Provisioning Mode
    uci set uhttpd.main.home='/www_provision'
    uci commit uhttpd
    /etc/init.d/uhttpd restart

    logger -t zero_trust "Blackout mode fully activated"

else
    # i just allowed the standard config to load
    echo "Zero-Trust: Verified. Booting Normally." > /dev/console
fi

exit 0
