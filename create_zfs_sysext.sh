#!/bin/bash
set -euo pipefail

export ARCH="${ARCH-amd64}"
SCRIPTFOLDER="$(dirname "$(readlink -f "$0")")"

if [ $# -lt 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0 VERSION SYSEXTNAME"
  echo "The script will download the Teleport release binaries (e.g., for v9.6.23) and create a sysext squashfs image with the name SYSEXTNAME.raw in the current folder."
  echo "A temporary directory named SYSEXTNAME in the current folder will be created and deleted again."
  echo "All files in the sysext image will be owned by root."
  echo "To use arm64 pass 'ARCH=arm64' as environment variable (current value is '${ARCH}')."
  "${SCRIPTFOLDER}"/bake.sh --help
  exit 1
fi

VERSION="$1"
SYSEXTNAME="$2"
if [ "${ARCH}" = aarch64 ]; then
  ARCH=arm64
fi
rm -f zfs

# base
ls -l /
echo $PWD
emerge-gitclone
echo 'FEATURES="-network-sandbox -pid-sandbox -ipc-sandbox -usersandbox -sandbox"' >>/etc/portage/make.conf



"${SCRIPTFOLDER}"/bake.sh "${SYSEXTNAME}"
rm -rf "${SYSEXTNAME}"
