#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

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


# Configures hostname / id
echo "archlive" > /etc/hostname
echo -n '' > /etc/machine-id
