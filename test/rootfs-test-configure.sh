#!/bin/bash
pacman --noconfirm -Sy openssh
sed -i "s/^#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitEmptyPasswords.*/PermitEmptyPasswords yes/g" /etc/ssh/sshd_config
systemctl enable sshd
