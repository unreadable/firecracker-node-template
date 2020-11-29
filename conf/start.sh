# Minimal init
rc-service sysfs start
rc-service networking start

# Set up interface
source /usr/buildenv
ip addr add $IP dev eth0
ip link set eth0 up
ip route add default via $GATEWAY dev eth0

# Run user program
echo "Running node"
# /usr/bin/node -e "console.log(22)"
/usr/bin/node --version
type -a node
type -a npm

# Shutdown firecracker
reboot