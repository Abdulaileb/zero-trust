#!/bin/bash

# Create TAP interfaces if they don't exist
if ! ip link show tap-std-wan &>/dev/null; then
    ip tuntap add tap-std-wan mode tap
    ip link set tap-std-wan up
    # Connect to br-lan for internet access
    ip link set tap-std-wan master br-wan
fi

if ! ip link show tap-std-lan &>/dev/null; then
    ip tuntap add tap-std-lan mode tap
    ip link set tap-std-lan up
    ip link set tap-std-lan master br-lan
fi

echo "Starting Standard OpenWrt (VULNERABLE baseline)..."
echo "After boot: root (no password), IP: 192.168.1.1"
echo ""

# Launch without KVM (Google Cloud compatible)
qemu-system-x86_64 \
  -m 512 \
  -nographic \
  -drive file=/root/openwrt-standard.qcow2,format=qcow2,if=virtio \
  -netdev tap,id=wan,ifname=tap-std-wan,script=no,downscript=no \
  -device virtio-net-pci,netdev=wan,mac=52:54:00:10:00:01 \
  -netdev tap,id=lan,ifname=tap-std-lan,script=no,downscript=no \
  -device virtio-net-pci,netdev=lan,mac=52:54:00:10:00:02

# Cleanup on exit
ip link delete tap-std-wan 2>/dev/null
ip link delete tap-std-lan 2>/dev/null