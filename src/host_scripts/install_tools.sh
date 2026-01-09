#!/bin/bash
echo "Installing Lab Dependencies..."
sudo apt-get update
sudo apt-get install -y qemu-system-x86 qemu-utils bridge-utils iproute2 sshpass
echo "Done."