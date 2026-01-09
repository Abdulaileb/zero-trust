#!/bin/bash
echo "Configuring Network Bridges..."

# 1. Standard LAN Bridge
if ! ip link show br-lan > /dev/null 2>&1; then
    sudo ip link add name br-lan type bridge
    sudo ip link set dev br-lan up
    sudo ip addr add 192.168.2.254/24 dev br-lan
fi

# 2. Management VLAN 99 Bridge
if ! ip link show br-lan.99 > /dev/null 2>&1; then
    sudo ip link add link br-lan name br-lan.99 type vlan id 99
    sudo ip link set dev br-lan.99 up
    sudo ip addr add 192.168.99.254/24 dev br-lan.99
fi

echo "Network Ready."




## Also
# #!/bin/bash
# # Setup network bridges
# brctl addbr lan-bridge
# brctl addbr vlan-bridge
# ip link set lan-bridge up
# ip link set vlan-bridge up


# Setup for auto create data
mkdir -p /www_provision/cgi-bin
chmod +x /www_provision/cgi-bin