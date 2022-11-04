
# Builds live image
live-img:
  earthly --allow-privileged +live-img

# Tests live image on qemu virtual machine
test-valid-image:
  earthly --allow-privileged +test-valid-image

# Launches docker container with live image controlled by tty
run:
  earthly --allow-privileged +image-with-image
  docker container run --privileged --rm -it archiso/run
  docker image rm archiso/run
