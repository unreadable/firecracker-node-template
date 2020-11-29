# Minimal init
rc-service sysfs start
rc-service networking start
rngd -r /dev/urandom

# Set up interface
source /usr/buildenv
ip addr add $IP dev eth0
ip link set eth0 up
ip route add default via $GATEWAY dev eth0

# Run user program
/usr/bin/node /usr/src/function/index.js

# Shutdown firecracker
reboot