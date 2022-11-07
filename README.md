## Archlive-builder
Archlive-builder is a builder (script) that allows you to build custom
archlinux live image. It uses earthly for fast execution, requirements
minimization, reliability and verbosity.

#### Requirements
- bash
- docker
- earthly

#### Build archlive image

```bash
# Creates clear image
./run build-live-image

# Creates custom image
export rootfs_configure_script="./rootfs_configure.sh"
export kernel_options="rw console=ttyS0"
./run build-live-image
```

Variable name | Default value | Required | Description
-|-|- | -
rootfs_configure_script | - | false | It configures rootfs from chroot
kernel_options | rw | false | It sets kernel boot options


---
#### Test building process
```bash
# It builds custom image and checks boot errors
./run test-live-image-boot
```


---
#### Run archlive image in terminal
```bash
# Builds archlive image with required kernel option "console=ttyS0"
export kernel_options="rw console=ttyS0"
./run build-live-image

# Launches ./output/live.img interactive in terminal
export launch_interactive_image="./output/live.img"
./run launch-interactive-tty
```

Variable name | Default value | Required | Description
-|-|- | -
launch_interactive_image | - | true | It sets image to boot
