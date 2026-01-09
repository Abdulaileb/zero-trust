root@zeroboot:~# cat setup_ns.sh
#!/bin/bash
# setup_ns.sh - Create namespaces and connect them to br-lan

# Create namespaces
ip netns add user_pc
ip netns add attacker_pc

# Create veth pairs
ip link add veth_user_host type veth peer name veth_user_pc
ip link add veth_hack_host type veth peer name veth_hack_pc

# Attach host ends to bridge
ip link set veth_user_host master br-lan
ip link set veth_user_host up
ip link set veth_hack_host master br-lan
ip link set veth_hack_host up

# Move peer ends into namespaces
ip link set veth_user_pc netns user_pc
ip link set veth_hack_pc netns attacker_pc


ip netns exec user_pc ip link set lo up
ip netns exec user_pc ip link set veth_user_pc up
ip netns exec user_pc ip addr add 192.168.2.100/24 dev veth_user_pc
ip netns exec user_pc ip route add default via 192.168.2.1


ip netns exec attacker_pc ip link set lo up
ip netns exec attacker_pc ip link set veth_hack_pc up
ip netns exec attacker_pc ip addr add 192.168.2.200/24 dev veth_hack_pc
ip netns exec attacker_pc ip route add default via 192.168.2.1

echo "User IP: 192.168.2.100 (Namespace: user_pc)"
echo "Attacker IP: 192.168.2.200 (Namespace: attacker_pc)"
root@zeroboot:~#
