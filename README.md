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
# Creates clear image "output/live.img"
./run build-live-image

# Creates custom image "output/live.img"
export rootfs_configure_script="./rootfs_configure.sh"
export kernel_options="rw console=ttyS0"
./run build-live-image
```

Variable name | Default value | Required | Description
-|-|- | -
rootfs_configure_script | - | false | It configures rootfs from chroot
kernel_options | rw | false | It sets kernel boot options

<details>
<summary> rootfs_configure_script example </summary>

```bash
#!/usr/bin/env bash
set -euo pipefail

# Downloads some packages
pacman -Sy nano tree vi npm

# Changes configs
echo "ee2e" > /etc/hostname

# Bulids some project
cd /root
ln -s /cache node_modules
npm i simple-js-project
```
Note that path `/cache` can be used as a cache betweet builds.

</details>


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


---
#### Test building process
```bash
# It builds custom image and checks boot errors
./run test-live-image-boot
```
