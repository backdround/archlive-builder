VERSION 0.6
FROM alpine:latest
WORKDIR /work
RUN apk upgrade --update && apk add --no-cache bash


pacstrap-alpine-image:
  # Installs required instuments.
  RUN apk add --update --no-cache pacman arch-install-scripts \
    pacman-makepkg curl tar zstd

  COPY ./pacman-configs /etc/

  # Installs pacman keyring.
  RUN pacman -Sy && \
    curl $(pacman -Sp archlinux-keyring | tail -n1) | tar -x --zstd -C / &&\
    pacman-key --init && pacman-key --populate && pacman -Syyu

  SAVE IMAGE pacstrap-alpine



kernel-and-initramfs:
  FROM +pacstrap-alpine-image

  # Gets kernel and builds initramfs by hooks
  COPY ./mkinitcpio.conf ./etc/
  RUN --mount=type=cache,target=./var/cache/pacman/pkg --privileged \
    pacstrap ./ sed linux mkinitcpio-archiso

  SAVE ARTIFACT ./boot/vmlinuz-linux ./ AS LOCAL ./output/
  SAVE ARTIFACT ./boot/initramfs-linux.img ./ AS LOCAL ./output/


systemd-boot:
  FROM +pacstrap-alpine-image

  RUN pacman -Sy && curl $(pacman -Sp systemd | tail -n1) | tar -x --zstd &&\
    cp ./usr/lib/systemd/boot/efi/systemd-bootx64.efi ./

  SAVE ARTIFACT systemd-bootx64.efi AS LOCAL ./output/


esp-image:
  RUN apk add --update --no-cache mtools dosfstools

  COPY ./make-fat.sh ./
  COPY --dir systemd-loader ./
  COPY +systemd-boot/systemd-bootx64.efi ./
  COPY +kernel-and-initramfs/vmlinuz-linux ./
  COPY +kernel-and-initramfs/initramfs-linux.img ./

  RUN \
    install -m 644 -D ./systemd-loader/loader.conf ./esp/loader/loader.conf &&\
    install -m 644 -D ./systemd-loader/entries/arch.conf ./esp/loader/entries/arch.conf &&\
    install -m 755 -D ./systemd-bootx64.efi ./esp/EFI/BOOT/BOOTx64.EFI &&\
    install -m 644 ./vmlinuz-linux ./esp/vmlinuz-linux &&\
    install -m 644 ./initramfs-linux.img ./esp/initramfs-linux.img

  RUN ./make-fat.sh ./esp ./esp.img ARCH_LIVE

  SAVE ARTIFACT ./esp.img ./ AS LOCAL ./output/


rootfs:
  FROM +pacstrap-alpine-image

  # Installs erofs
  RUN apk --update --no-cache add git automake autoconf libtool g++ pkgconf \
    util-linux-dev make lz4-dev &&\
    git clone https://git.kernel.org/pub/scm/linux/kernel/git/xiang/erofs-utils.git &&\
    ( cd erofs-utils && ./autogen.sh && ./configure && make && make install ) &&\
    rm -rf erofs-utils

  # Creates rootfs
  COPY ./rootfs-configure.sh ./
  RUN --mount=type=cache,target=./root/var/cache/pacman/pkg --privileged \
    mkdir -p ./root && pacstrap ./root base linux &&\
    arch-chroot ./root < ./rootfs-configure.sh

  # Builds rootfs
  RUN mkfs.erofs '-zlz4hc,2' -E ztailpacking ./airootfs.erofs ./root &&\
    sha512sum ./airootfs.erofs > airootfs.sha512

  SAVE ARTIFACT ./airootfs.erofs ./ AS LOCAL ./output/
  SAVE ARTIFACT ./airootfs.sha512 ./ AS LOCAL ./output/


live-iso:
  RUN apk add --update --no-cache xorriso

  COPY \
    +esp-image/esp.img \
    +rootfs/airootfs.erofs \
    +rootfs/airootfs.sha512 \
    .

  RUN \
    install -m 644 -D ./esp.img ./iso/esp.img &&\
    install -m 644 -D ./airootfs.erofs ./iso/arch/x86_64/airootfs.erofs &&\
    install -m 644 -D ./airootfs.sha512 ./iso/arch/x86_64/airootfs.sha512 &&\
    xorrisofs -r \
      -V "ARCH_LIVE" \
      -e esp.img \
      --no-emul-boot \
      -o ./live.iso \
      ./iso

  SAVE ARTIFACT ./live.iso AS LOCAL ./output/
