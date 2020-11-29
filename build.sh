#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "No handler path specified"
    echo "Run as sudo ./build.sh <handler-path>"
    exit 0
fi

IP=172.20.0.2/24
GATEWAY=172.20.0.1

mkcp() {
    test -d "$2" || mkdir -p "$2"
    cp -r "$1" "$2"
}

KERNEL=vmlinux.bin
ALPINE_ROOTFS=alpine-minirootfs
CODEDIR=$(pwd)/$1

echo "Configuring vm file system.."
sudo rm -rf /tmp/{overlay,rootfs,tmp} ./rootfs

mkcp conf/inittab /tmp/overlay/etc
mkcp conf/interfaces /tmp/overlay/etc/network
mkcp conf/start.sh /tmp/overlay
mkcp conf/resolv.conf /tmp/overlay/etc

dd if=/dev/zero of=/tmp/rootfs bs=1M count=50
mkfs.ext4 /tmp/rootfs

mkdir /tmp/tmp
mount /tmp/rootfs /tmp/tmp -o loop

if [[ ! $(find /tmp -name $KERNEL) ]]; then
    echo "No kernel found, fetching one.."
    wget https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin -O /tmp/$KERNEL
fi

if [[ ! $(find /tmp -name $ALPINE_ROOTFS) ]]; then
    echo "No root file system found, fetching one.."
    wget -c  http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/x86_64/alpine-minirootfs-3.12.1-x86_64.tar.gz -O - | tar -xz -C /tmp/tmp
fi

cp -r /tmp/overlay/* /tmp/tmp/

mkdir /tmp/tmp/usr/src
rsync -av --progress $CODEDIR /tmp/tmp/usr/src --exclude node_modules

cat > /tmp/tmp/usr/buildenv <<EOF
IP=$IP
GATEWAY=$GATEWAY
EOF

echo "Installing vm dependencies"
cat > /tmp/tmp/prepare.sh <<EOF
passwd root -d root
apk add -u openrc ca-certificates nodejs
exit 
EOF

chroot /tmp/tmp/ /bin/sh /prepare.sh

rm /tmp/tmp/prepare.sh 

umount /tmp/tmp

echo "Exporting vm file system"
cp /tmp/rootfs .

echo "Cleaning up remaining files.."
sudo rm -rf /tmp/{overlay,rootfs,tmp}
