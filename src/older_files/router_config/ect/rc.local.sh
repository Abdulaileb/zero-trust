if [ ! -f /etc/config/zero_trust_complete ]; then
    # this is the file

    logger -t zero_trust "Zero Trust setup not complete, skipping rc.local actions"

    #1. physically bring down the WAN interface 
    ip link set dev eth1 down

    ## 2. setting up the firewall rules to block all traffic except to/from the management VLAN (VLAN 99)
    uci set firewall.@zone[1].input='REJECT'
    uci set firewall.@zone[1].output='REJECT'
    uci set firewall.@zone[1].forward='REJECT' to indicate zero trust setup is complete
    uci commit firewall
    /etc/init.d/firewall reload
fi

exit 0



### ANother one

# root@OpenWrt:/# cat /etc/rc.local
# # Put your custom commands here that should be executed once
# # the system init finished. By default this file does nothing.

# if [ ! -f /etc/config/zero_trust_complete ]; then
#      logger -t zero_trust "Device unprovisioned. Enforcing WAN BLACKOUT."

#      ## Physically bring down the WAN interface
#      #ip link set eth1 down
#      ifdown wan
#      uci set network.wan.auto='0'
#      uci commit network

#      ### Force the Web Server to Provisioning Mode
#      uci set uhttpd.main.home='/www_provision'
#      uci commit uhttpd
#      /etc/init.d/uhttpd restart

#       ## 2. Ensure the firewall blocks everything just in case
#       uci set firewall.@zone[1].input='REJECT'
#       uci set firewall.@zone[1].output='REJECT'
#       uci set firewall.@zone[1].forward='REJECT'
#       uci commit firewall
#       /etc/init.d/firewall reload
# else
#       echo "Zero-Trust: Verified. Booting Normally." > /dev/console
# fi

# exit 0


# #####
# root@OpenWrt:/# nano /etc/rc.local
#   GNU nano 8.5                     /etc/rc.local
# #!/bin/sh
# # Put your custom commands here that should be executed once
# # the system init finished. By default this file does nothing.

# if [ ! -f /etc/config/zero_trust_complete ]; then
#     logger -t zero_trust "Device unprovisioned. Enforcing WAN BLACKOUT."

#     # Wait for network subsystem to be ready
#     #sleep 5

#     ## 1. Disable WAN interface
#     # Multiple approaches for reliability
#     ifdown wan 2>/dev/null
#     ip link set eth1 down 2>/dev/null

#     # Disable auto-start for WAN
#     uci set network.wan.auto='0'
#     uci set network.wan.enabled='0'
#     uci commit network
#     /etc/init.d/network restart


# root@OpenWrt:/# cat /etc/rc.local
# #!/bin/sh
# # Put your custom commands here that should be executed once
# # the system init finished. By default this file does nothing.

# if [ ! -f /etc/config/zero_trust_complete ]; then
#     logger -t zero_trust "Device unprovisioned. Enforcing WAN BLACKOUT."

#     # Wait for network subsystem to be ready
#     #sleep 5

#     ## 1. Disable WAN interface
#     # Multiple approaches for reliability
#     ifdown wan 2>/dev/null
#     ip link set eth1 down 2>/dev/null

#     # Disable auto-start for WAN
#     uci set network.wan.auto='0'
#     uci set network.wan.enabled='0'
#     uci commit network
#     /etc/init.d/network restart

#     ## 2. Force Web Server to Provisioning Mode
#     uci set uhttpd.main.home='/www_provision'
#     uci commit uhttpd
#     /etc/init.d/uhttpd restart

#     ## 3. More robust firewall blocking
#     # Block by zone name instead of index
#     uci set firewall.@zone[1].input='REJECT'
#     uci set firewall.@zone[1].output='REJECT'
#     uci set firewall.@zone[1].forward='REJECT'

#     # Add explicit rule to block all WAN traffic
#     uci add firewall rule
#     uci set firewall.@rule[-1].name='Block-All-WAN'
#     uci set firewall.@rule[-1].src='wan'
#     uci set firewall.@rule[-1].dest='lan'
#     uci set firewall.@rule[-1].target='REJECT'
#     uci set firewall.@rule[-1].proto='all'
#     uci set firewall.@rule[-1].family='any'

#     uci commit firewall

#     # Force full firewall restart, not just reload
#     /etc/init.d/firewall stop
#     sleep 2
#     /etc/init.d/firewall start

#     # Create a marker that script ran
#     touch /tmp/zero_trust_applied

#     logger -t zero_trust "Blackout mode fully activated"

# else
#     echo "Zero-Trust: Verified. Booting Normally." > /dev/console
# fi

# exit 0
# root@OpenWrt:/#


### NOW USED ###

root@OpenWrt:/# cat /etc/rc.local
# the system init finished. By default this file does nothing.

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
root@OpenWrt:/#

