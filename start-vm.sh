#!/bin/bash

GATEWAY=172.20.0.1
MAC_FILE=/sys/class/net/tap0/address
SOCKET_PATH=/tmp/firecracker.socket

rm -f $SOCKET_PATH

if [ ! -f $MAC_FILE ]; then
    sudo ip tuntap add tap0 mode tap
    sudo ip addr add $GATEWAY/24 dev tap0
    sudo ip link set tap0 up

    DEVICE_NAME=eth0

    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo iptables -t nat -A POSTROUTING -o $DEVICE_NAME -j MASQUERADE
    sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i tap0 -o $DEVICE_NAME -j ACCEPT
fi

MAC="$(cat $MAC_FILE)"

sudo firectl \
    --kernel=/tmp/vmlinux.bin \
    --root-drive=rootfs \
    --kernel-opts="console=ttyS0 random.trust_cpu=on noapic reboot=k panic=1 pci=off nomodules rw" \
    --tap-device=tap0/$MAC \
    --socket-path=$SOCKET_PATH \
    --ncpus=8
