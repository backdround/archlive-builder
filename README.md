## Archlive-builder
Archlive-builder is a builder (script) that allows you to build custom
archlinux live image. It uses `earthly` for fast execution, requirements
minimization, reliability and verbosity.

#### Requirements
- bash
- docker
- earthly

#### Build archlive image

```bash
# It configures archiso rootfs from chroot
#
# optional: true
# default: -
export rootfs_configure_script="./rootfs_configure.sh"

# It sets kernel boot options
#
# optional: true
# default: rw
export kernel_options="rw console=ttyS0"

# Creates custom image "output/live.img"
./run build-live-image
```

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
# It sets image to boot.
# Image has to be bootable from terminal.
# (for example with `console=ttyS0` kernel option)
#
# optional: false
export launch_interactive_image="./output/live.img"

# Launches ./output/live.img interactive in terminal
./run launch-interactive-tty
```

---
#### Test builder itself
```bash
# It builds custom image and checks boot errors by ssh
./run test-buidler
```
