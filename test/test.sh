#!/bin/bash
# Test runs live image in the virtual machine, connects to ssh server
# and checks that services are successfully started.
# Usage:
# ./test.sh ./image.img ./OVMF_CODE.fd

set -o errexit
set -o pipefail
set -o nounset


error() {
  echo $@ >&2
  return 1
}

image_file="${1:-}"
ovmf_code="${2:-}"


# Checks arguments
test ! -f "$image_file" &&\
  error "First argument must be an image file"

test ! -f "$ovmf_code" &&\
  error "Second argument must be an OVMF_CODE.fd file"


# Boots image file in the background
port="60022"
qemu-system-x86_64 \
  -nographic \
  -enable-kvm -smp 6 -m 4G \
  -nic user,hostfwd=tcp::$port-:22 \
  -drive "if=pflash,format=raw,readonly=true,file=$ovmf_code" \
  -drive "if=virtio,format=raw,file=$image_file" > /dev/null < /dev/null &
qemu_pid="$!"


# Stops qemu on exit
stop_qemu() {
  echo "Exiting"
  kill -SIGKILL "$qemu_pid"
}
trap stop_qemu EXIT


# Checks that port is open
timeout 10 bash -c "while ! nc -z 127.0.0.1 $port ; do sleep 0.1 ; done" || {
  error "Unable to boot qemu"
}
echo "Qemu started live image"


# Checks that live image is bootable
echo "Waiting live image boot"
ssh_options="-o UserKnownHostsFile=/dev/null
  -o StrictHostKeyChecking=no
  -o LogLevel=ERROR"
timeout 120 ssh $ssh_options root@127.0.0.1 -p $port -T exit || {
  error "Unable to connect to ssh server"
}
echo "Live image is connactable"


# Checks that live image boots withouth failed services
failed_services="$(ssh root@127.0.0.1 -p $port -T $ssh_options \
  systemctl list-units --legend=false --state=falied)"

if [ ! -z "$failed_services" ]; then
  error "archlive failed with services:\n$failed_services"
fi
echo "Live image starts without failed services"

# Exits Successfully
exit 0
