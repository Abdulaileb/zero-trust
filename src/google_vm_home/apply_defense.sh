root@zeroboot:~# cat apply_defense.sh
#!/bin/bash
# 3_apply_defense.sh - SECURE THE BRIDGE
#echo "--- Applying VLAN Filtering (ACLs) ---"

# 1. Enable VLAN Awareness
ip link set dev br-lan type bridge vlan_filtering 1

# 2. Configure Ports
# Router Port (TRUNK) - Allow 1 and 99
bridge vlan add dev tap0 vid 1 pvid untagged
bridge vlan add dev tap0 vid 99

# Attacker Port (ACCESS) - Block 99
bridge vlan add dev veth_hack_host vid 1 pvid untagged
bridge vlan del dev veth_hack_host vid 99 2>/dev/null

# User Port (ACCESS) - Block 99
bridge vlan add dev veth_user_host vid 1 pvid untagged
bridge vlan del dev veth_user_host vid 99 2>/dev/null

# Host Port (Management)
bridge vlan add dev br-lan vid 1 pvid untagged self
bridge vlan add dev br-lan vid 99 self

echo " DONE with the ACLs Applied. Re-testing Attack... "
root@zeroboot:~#
