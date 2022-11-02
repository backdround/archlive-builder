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

  # Gets kernel and builds custom initramfs by hooks
  RUN install -m 755 -d ./etc/initcpio/{install,hooks}
  COPY ./initramfs/mkinitcpio.conf ./etc/
  COPY ./initramfs/initramfs_build_hook ./etc/initcpio/install/overlay_over_partition
  COPY ./initramfs/initramfs_run_hook ./etc/initcpio/hooks/overlay_over_partition

  RUN --mount=type=cache,target=./var/cache/pacman/pkg --privileged \
    pacstrap ./ sed linux mkinitcpio

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
  COPY ./rootfs/rootfs-pre-configure.sh ./
  RUN --mount=type=cache,target=./root/var/cache/pacman/pkg --privileged \
    mkdir -p ./root && pacstrap ./root base linux &&\
    arch-chroot ./root < ./rootfs-pre-configure.sh

  # Configures rootfs by user's script
  ARG rootfs_configure
  IF [ ! -z "$rootfs_configure" ]
    COPY "$rootfs_configure" ./root/do.sh
    RUN --privileged chmod +x ./root/do.sh &&\
      arch-chroot ./root /do.sh && rm -rf ./root/do.sh
  END

  # Cleanes up and builds rootfs
  RUN --privileged rm -rf ./root/boot/* ./root/var/lib/pacman/sync/* \
    ./root/var/log/* ./root/.bash_history && \
    mkfs.erofs '-zlz4hc,2' -E ztailpacking ./airootfs.erofs ./root

  SAVE ARTIFACT ./airootfs.erofs ./ AS LOCAL ./output/


live-iso:
  RUN apk add --update --no-cache sfdisk mtools uuidgen

  COPY ./make-image.sh ./

  COPY \
    +esp-image/esp.img \
    +rootfs/airootfs.erofs \
    ./

  ARG kernel_options="rw"

  # Generates random rootfs uuid and escpaes kernel options.
  RUN --no-cache uuidgen > rootfs_uuid.txt &&\
    echo -E "$kernel_options" | sed 's/[/\&]/\\&/g' > kernel_options.txt

  # Changes kernel boot options.
  RUN mcopy -i ./esp.img ::/loader/entries/arch.conf . &&\
    sed -i "s/{{partuuid}}/$(cat rootfs_uuid.txt)/g;" ./arch.conf &&\
    sed -i "s/{{kernel_options}}/$(cat kernel_options.txt)/g;" ./arch.conf &&\
    mcopy -D o -i ./esp.img ./arch.conf ::/loader/entries/arch.conf

  ## Creates live disk image
  RUN ./make-image.sh ./esp.img ./airootfs.erofs "$(cat rootfs_uuid.txt)" ./live.img

  SAVE ARTIFACT ./live.img AS LOCAL ./output/
