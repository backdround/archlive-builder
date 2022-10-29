#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

error() {
  echo $@ >&2
  return 1
}

# Gets filesystem images
esp="${1:-}"
rootfs="${2:-}"
image="${3:-}"
test ! -f "$esp" && error "First argument must be an esp image file path"
test ! -f "$rootfs" && error "Second argument must be an rootfs image file path"
test -z "$image" && error "Third argument must be an building disk image file path"


# Calculates files sectors
esp_size_in_bytes=$(stat -c %s "$esp")
esp_offset_in_sectors="34"
esp_size_in_sectors=$((esp_size_in_bytes / 512 + 1))

rootfs_size_in_bytes=$(stat -c %s "$rootfs")
rootfs_offset_in_sectors=$((esp_offset_in_sectors + esp_size_in_sectors))
rootfs_size_in_sectors=$((rootfs_size_in_bytes / 512 + 1))

# Creates image file
disk_size_in_bytes=$(( (esp_size_in_sectors + rootfs_size_in_sectors + 34 * 2) * 512 ))
truncate -s "$disk_size_in_bytes" "$image"

# Parts image file
echo "\
label: gpt
first-lba: $esp_offset_in_sectors

start=$esp_offset_in_sectors, size=$esp_size_in_sectors, \
  type=c12a7328-f81f-11d2-ba4b-00a0c93ec93b

start=$rootfs_offset_in_sectors, size=$rootfs_size_in_sectors, \
  type=0fc63daf-8483-4772-8e79-3d69d8477de4, uuid=518fb369-0226-4ee1-87f7-15bd0cf05de5

write
" | sfdisk "$image"

# Injects filesystem images
dd if="$esp" of="$image" seek="$esp_offset_in_sectors" bs=512 conv=notrunc
dd if="$rootfs" of="$image" seek="$rootfs_offset_in_sectors" bs=512 conv=notrunc