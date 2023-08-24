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
emerge-gitclone
echo 'FEATURES="-network-sandbox -pid-sandbox -ipc-sandbox -usersandbox -sandbox"' >>/etc/portage/make.conf
cp files/zfs/repos.conf /etc/portage/repos.conf/zfs.conf
cp -r files/zfs/overlay/ /var/lib/portage/zfs-overlay/
kernel=$(ls /lib/modules) && KBUILD_OUTPUT=/lib/modules/${kernel}/build KERNEL_DIR=/lib/modules/${kernel}/source emerge -j16 --getbinpkg --onlydeps zfs
emerge -j16 --getbinpkg --buildpkgonly zfs squashfs-tools
cat /lib/modules/5.15.122-flatcar/modules.dep



"${SCRIPTFOLDER}"/bake.sh "${SYSEXTNAME}"
rm -rf "${SYSEXTNAME}"
