
# Builds live image
build-live-image:
  earthly --allow-privileged +live-image

# Tests live image boot on qemu virtual machine
test-live-image-boot:
  earthly --allow-privileged +test-live-image-boot

# Launches docker container interactive with live image controlled by tty
run:
  earthly --allow-privileged +docker-image-with-live-image
  docker container run --privileged --rm -it archlive/live-image
  docker image rm archlive/live-image
