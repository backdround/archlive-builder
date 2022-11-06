# This file is the main start point for the project.
# Usage:
# just option_name=value recipe_name


# Builds options
rootfs_configure_script_path := "NOT_SETTED"
kernel_options := "NOT_SETTED"

# Builds live image
build-live-image:
  #!/usr/bin/env -S bash -euo pipefail

  build_options=()

  # Gets base64 option
  if [[ "{{rootfs_configure_script_path}}" != "NOT_SETTED" ]]; then
    echo "rootfs_configure_script_path: {{rootfs_configure_script_path}}"

    get_base64_command=(
      ".just/do"
      "get_rootfs_configure_script_base64"
      "{{invocation_directory()}}"
      "{{rootfs_configure_script_path}}"
    )

    base64="$("${get_base64_command[@]}")"
    build_options+=("--rootfs_configure_base64=$base64")
  fi

  # Gets kernel option
  if [[ "{{kernel_options}}" != "NOT_SETTED" ]]; then
    echo "kernel_options: {{kernel_options}}"
    build_options+=(--kernel_options="{{kernel_options}}")
  fi

  # Launches archlive build
  earthly --allow-privileged +live-image "${build_options[@]}"


# Tests live image boot on qemu virtual machine
test-live-image-boot:
  earthly --allow-privileged +test-live-image-boot


# Launches docker container interactive with live image controlled by tty
run:
  earthly --allow-privileged +docker-image-with-live-image
  docker container run --privileged --rm -it archlive/live-image
  docker image rm archlive/live-image
