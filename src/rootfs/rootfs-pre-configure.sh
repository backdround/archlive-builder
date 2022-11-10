#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set +o history

# Fix package installation under arch-chroot.
sed -i "s/CheckSpace/#CheckSpace/g" /etc/pacman.conf


# Configures network.
install -m 755 -d /etc/systemd/network
cat > /etc/systemd/network/20-ethernet.network <<EOF
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes
EOF

systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service


# Configures autologin
install -m 755 -d /etc/systemd/system/getty@.service.d/
cat > /etc/systemd/system/getty@.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root %I \$TERM
EOF
passwd -d root

# Enables timesync
install -m 755 -d /etc/systemd/system/sysinit.target.wants
ln -sf /usr/lib/systemd/system/systemd-timesyncd.service \
  /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service
ln -sf /usr/lib/systemd/system/systemd-time-wait-sync.service \
  /etc/systemd/system/sysinit.target.wants/systemd-time-wait-sync.service

# Configures hostname / id
echo "archlive" > /etc/hostname
echo -n '' > /etc/machine-id


# Cleans all cache
rm -rf /boot/* /var/lib/pacman/sync/* /var/log/*
history -c
