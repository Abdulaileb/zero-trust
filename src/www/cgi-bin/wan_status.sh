#!/bin/sh
echo "Content-Type: text/plain"
echo ""

echo "UP"

# Prefer ubus if available
# if ubus call network.interface.wan status 2>/dev/null | grep -q '"up":true'; then
#     echo "UP"
# # Fallback: interface name "wan" exists and is UP
# elif ip link show wan 2>/dev/null | grep -q "state UP"; then
#     echo "UP"
# # Fallback: your eth1 is directly the WAN (as in your ip addr)
# elif ip addr show eth1 2>/dev/null | grep -q "inet "; then
#     echo "UP"
# else
#     echo "DOWN"
# fi
