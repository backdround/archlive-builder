VERSION 0.6
FROM alpine:latest
WORKDIR /work
RUN apk upgrade --update && apk add --no-cache bash
IMPORT --allow-privileged ./src/


# Builds arch live image
live-image:
  ARG rootfs_configure_base64
  ARG kernel_options

  COPY (src+live-image/live.img \
    --rootfs_configure_base64="$rootfs_configure_base64" \
    --kernel_options="$kernel_options" \
    ) \
    .
  SAVE ARTIFACT ./live.img AS LOCAL output/live.img


# Validates arch live image. It boots live image and checks failed services
test-live-image-boot:
  RUN apk add --update --no-cache \
    qemu-system-x86_64 qemu-modules ovmf openssh &&\
    cp /usr/share/OVMF/OVMF_CODE.fd ./

  COPY \
    ./test/test.sh \
    ./test/rootfs-test-configure.sh \
    .

  ARG rootfs_configure_base64="$(cat ./rootfs-test-configure.sh | base64 -w 0)"
  COPY (src+live-image/live.img \
    --rootfs_configure_base64="$rootfs_configure_base64" \
    --kernel_options="rw console=ttyS0" \
    --use_random_rootfs_uuid=false) \
    .

  RUN --privileged ./test.sh ./live.img ./OVMF_CODE.fd

# Makes docker image for start mounted arch image on vm
launcher-image:
  WORKDIR /work
  RUN apk add --update --no-cache \
    qemu-system-x86_64 qemu-modules ovmf &&\
    cp /usr/share/OVMF/OVMF_CODE.fd ./

  IF [ ! -z "$(lsmod | grep kvm)" ]
    ENV kvm_flag="-enable-kvm"
  ELSE
    ENV kvm_flag=""
  END

  ENV additional_qemu_flags=""

  ENTRYPOINT qemu-system-x86_64 \
    \$additional_qemu_flags \$kvm_flag -smp 6 -m 4G \
    -drive "if=pflash,format=raw,readonly=true,file=./OVMF_CODE.fd" \
    -drive "if=virtio,format=raw,file=./live.img"

  SAVE IMAGE archlive/launcher
