VERSION 0.6
FROM alpine:latest
WORKDIR /work
RUN apk update && apk upgrade

pacstrap-alpine-image:
  # Installs required instuments.
  RUN apk add pacman arch-install-scripts pacman-makepkg curl tar zstd

  COPY ./pacstrap-etc /etc/

  # Installs pacman keyring.
  RUN pacman -Sy && \
    curl $(pacman -Sp archlinux-keyring | tail -n1) | tar -x --zstd -C / &&\
    pacman-key --init && pacman-key --populate && pacman -Syyu

  SAVE IMAGE pacstrap-alpine



kernel-and-initramfs:
  FROM +pacstrap-alpine-image

  # Gets kernel and builds initramfs by hooks
  RUN --mount=type=cache,target=./var/cache/pacman/pkg --privileged \
    pacstrap ./ sed linux mkinitcpio-archiso

  SAVE ARTIFACT ./boot/vmlinuz-linux AS LOCAL ./output/
  SAVE ARTIFACT ./boot/initramfs-linux.img AS LOCAL ./output/


systemd-boot:
  FROM +pacstrap-alpine-image

  RUN pacman -Sy && curl $(pacman -Sp systemd | tail -n1) | tar -x --zstd &&\
    cp ./usr/lib/systemd/boot/efi/systemd-bootx64.efi ./

  SAVE ARTIFACT systemd-bootx64.efi AS LOCAL ./output/
