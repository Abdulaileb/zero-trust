root@zeroboot:~# cat reset_lab.sh
#!/bin/bash
# 0_reset_lab.sh - CLEAN SLATE
echo "Clearing up the Virtual Lab "

# 1. Kill Virtual Namespaces (Forcefully)
ip netns del user_pc 2>/dev/null
ip netns del attacker_pc 2>/dev/null

# 2. Delete Cables
ip link del veth_user_host 2>/dev/null
ip link del veth_hack_host 2>/dev/null

# 3. Disable VLAN Filtering (Revert to Dumb Hub Mode)
# This is crucial so the attack WORKS in Step 2
echo "Disabling Bridge VLAN Filtering..."
ip link set dev br-lan type bridge vlan_filtering 0

echo "Lab is Clean. Ready for Demo. "
root@zeroboot:~#
