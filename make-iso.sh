#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset


# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root" >&2
  exit 1
fi

# Clear and enter in work direcotry
work_directory="./build"
test -d "$work_directory" && rm -rf "$work_directory"
install -m 755 -o 0 -g 0 -d "$work_directory"
cd "$work_directory"


# Create root file system
install -m 755 -o 0 -g 0 -d ./root
install -m 755 -o 0 -g 0 -d ./root/etc

cat > ./root/etc/mkinitcpio.conf << END
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev modconf archiso block filesystems)
END

pacstrap "./root" base linux mkinitcpio-archiso

# Get kernel and initramfs
cp ./root/boot/vmlinuz-linux ./
cp ./root/boot/initramfs-linux.img ./

# Cleanup airootfs

# Delete all files in /boot
[[ -d "./root/boot" ]] && find "./root/boot" -mindepth 1 -delete
# Delete pacman database sync cache files (*.tar.gz)
[[ -d "./root/var/lib/pacman" ]] && find "./root/var/lib/pacman" -maxdepth 1 -type f -delete
# Delete pacman database sync cache
[[ -d "./root/var/lib/pacman/sync" ]] && find "./root/var/lib/pacman/sync" -delete
# Delete pacman package cache
[[ -d "./root/var/cache/pacman/pkg" ]] && find "./root/var/cache/pacman/pkg" -type f -delete
# Delete all log files, keeps empty dirs.
[[ -d "./root/var/log" ]] && find "./root/var/log" -type f -delete
# Delete all temporary files and dirs
[[ -d "./root/var/tmp" ]] && find "./root/var/tmp" -mindepth 1 -delete
# Delete package pacman related files.
find "./root" \( -name '*.pacnew' -o -name '*.pacsave' -o -name '*.pacorig' \) -delete
# Create an empty /etc/machine-id
rm -f -- "./root/etc/machine-id"
echo -n '' > "./root/etc/machine-id"

mkfs.erofs '-zlz4hc,2' -E ztailpacking ./airootfs.erofs ./root
sha512sum ./airootfs.erofs > airootfs.sha512

# Get bootloader
pacman --noconfirm -Sw --cachedir ./boot_loader systemd
( cd ./boot_loader && tar -xf ./systemd*.zst )
cp ./boot_loader/usr/lib/systemd/boot/efi/systemd-bootx64.efi ./

cat > ./loader.conf << END
default arch.conf
timeout 4
console-mode max
editor no
END

cat > arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options archisobasedir=arch archisolabel=ARCH_LIVE
END


# Create esp directory tree
mkdir ./esp
cp ./vmlinuz-linux ./esp/
cp ./initramfs-linux.img ./esp/

mkdir -p ./esp/EFI/BOOT
cp ./systemd-bootx64.efi ./esp/EFI/BOOT/BOOTx64.EFI

mkdir -p ./esp/loader/entries
cp ./loader.conf ./esp/loader
cp ./arch.conf ./esp/loader/entries


# Make EFI system partition image
fat_size=$(du --bytes --total ./esp | awk 'END { print $1 }')
mkfs.fat -C -n "ARCHISO_ESP" esp.img "$((fat_size / 1024 + 2048))"
files="$(cd ./esp && find ./ -type f)"
for file in $files; do
  # Recursive directory creation.
  path="$(dirname $file)"
  create_fat_directory() {
    if [[ "$1" != "." ]]; then
      # Create parent directory
      create_fat_directory "$(dirname "$1")"
      echo "create: ::/$1"
      mmd -D s -i esp.img "::/$1" || true
    fi
  }
  create_fat_directory "$path"
  # Copy file
  mcopy -i esp.img "./esp/$file" ::/$path
done

# Create iso image tree
mkdir iso_image
cp esp.img ./iso_image

mkdir -p ./iso_image/arch/x86_64
cp ./airootfs.erofs ./iso_image/arch/x86_64
cp ./airootfs.sha512 ./iso_image/arch/x86_64


# Create iso
xorrisofs -r \
  -V "ARCH_LIVE" \
  -e esp.img \
  --no-emul-boot \
  -o ./image.iso \
  ./iso_image
