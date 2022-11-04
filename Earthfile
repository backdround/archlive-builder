VERSION 0.6
FROM alpine:latest
WORKDIR /work
RUN apk upgrade --update && apk add --no-cache bash
IMPORT --allow-privileged ./src/


# Builds arch live image
live-img:
  COPY src+live-img/live.img .
  SAVE ARTIFACT ./live.img AS LOCAL output/live.img


# Validates arch live image. It boots live image and checks failed services
test-valid-image:
  RUN apk add --update --no-cache \
    qemu-system-x86_64 qemu-modules ovmf openssh &&\
    cp /usr/share/OVMF/OVMF_CODE.fd ./

  COPY \
    ./test/test.sh \
    ./test/rootfs-test-configure.sh \
    .

  ARG rootfs_configure_base64="$(cat ./rootfs-test-configure.sh | base64 -w 0)"
  COPY (src+live-img/live.img \
    --rootfs_configure_base64="$rootfs_configure_base64" \
    --kernel_options="rw console=ttyS0") \
    .

  RUN --privileged ./test.sh ./live.img ./OVMF_CODE.fd
