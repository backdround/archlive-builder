#!/bin/bash
# Usage
# ./make-fat.sh ./directory new-fat.img "FAT_LABEL"

set -o errexit
set -o pipefail
set -o nounset

error() {
  echo $@ >&2
  return 1
}

directory="$1"
image_file="$2"
volume_name="$3"


# Checks arguments
test ! -d "$directory" &&\
  error "First argument is not a direcotry"

test -z "$image_file" &&\
  error "Second argument must be an image file name"

test -z "$volume_name" &&\
  error "Third argument must be an image file name"


create_fat_directory() {
  local path="$1"
  local image_file="$2"

  test -z "$path" &&\
    error "Incorrect function usage: First argument must be a path"

  test -z "$image_file" &&\
    error "Incorrect function usage: Second argument must be an image file"

  # Checks path end
  if [[ "$path" == "." ]]; then
    return 0
  fi

  # Creates parent directory
  create_fat_directory "$(dirname "$path")" "$image_file"

  # Creates current directory
  mmd -D s -i "$image_file" "::/$path" || true
}

# Creates fat image file.
fat_size=$(du -s "$directory" | grep -o "^\S*")
mkfs.fat -C -n "$volume_name" "$image_file" "$((fat_size + 2048))"

# Copies directory files in image file
files="$(cd "$directory" && find ./ -type f)"
for file in $files; do
  path="$(dirname $file)"
  create_fat_directory "$path" "$image_file"
  mcopy -i "$image_file" "$directory/$file" "::/$path"
done
