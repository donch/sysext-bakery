#!/bin/bash
set -euo pipefail

export ARCH="${ARCH-amd64}"
SCRIPTFOLDER="$(dirname "$(readlink -f "$0")")"

if [ $# -lt 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0 VERSION SYSEXTNAME FLATCARVERSION"
  echo "The script will build ZFS modules and tooling and create a sysext squashfs image with the name SYSEXTNAME.raw in the current folder."
  echo "A temporary directory named SYSEXTNAME in the current folder will be created and deleted again."
  echo "All files in the sysext image will be owned by root."
  echo "To use arm64 pass 'ARCH=arm64' as environment variable (current value is '${ARCH}')."
  "${SCRIPTFOLDER}"/bake.sh --help
  exit 1
fi

VERSION="$1"
SYSEXTNAME="$2"
FLATCARVERSION="$3"
if [ "${ARCH}" = aarch64 ]; then
  ARCH=arm64
fi
rm -f ${SYSEXTNAME}

# base
emerge-gitclone
echo 'FEATURES="-network-sandbox -pid-sandbox -ipc-sandbox -usersandbox -sandbox"' >>/etc/portage/make.conf
cp files/zfs/repos.conf /etc/portage/repos.conf/zfs.conf
cp -r files/zfs/${FLATCARVERSION}/overlay/ /var/lib/portage/zfs-overlay/

# build zfs
kernel=$(ls /lib/modules) && KBUILD_OUTPUT=/lib/modules/${kernel}/build KERNEL_DIR=/lib/modules/${kernel}/source emerge -j2 --getbinpkg --onlydeps zfs
emerge -j2 --getbinpkg --buildpkgonly zfs squashfs-tools
cat /lib/modules/5.15.122-flatcar/modules.dep

# install deps 
emerge --getbinpkg --usepkg squashfs-tools

# flatcar layout compat
mkdir -p /work ; for dir in lib lib64 bin sbin; do mkdir -p /work/usr/$dir; ln -s usr/$dir /work/$dir; done
cp -r /lib/modules/${kernel} ${SYSEXTNAME}/lib/modules/${kernel}
pkgs=$(emerge 2>/dev/null --usepkgonly --pretend zfs| awk -F'] ' '/binary/{ print $ 2 }' | awk '{ print "="$1 }'); emerge --usepkgonly --root=${SYSEXTNAME} --nodeps $pkgs
mkdir -p ${SYSEXTNAME}/usr/lib/extension-release.d && echo -e 'ID=flatcar\nSYSEXT_LEVEL=1.0' >${SYSEXTNAME}/usr/lib/extension-release.d/extension-release.zfs
mkdir -p ${SYSEXTNAME}/usr/src
mv ${SYSEXTNAME}/etc ${SYSEXTNAME}/usr/etc
cp -r files/zfs/usr/ ${SYSEXTNAME}/usr/
rm -rf ${SYSEXTNAME}/var/db
rm -rf ${SYSEXTNAME}/var/cache
rm -rf ${SYSEXTNAME}/usr/share
rm -rf ${SYSEXTNAME}/usr/src
rm -rf ${SYSEXTNAME}/usr/include



"${SCRIPTFOLDER}"/bake.sh "${SYSEXTNAME}"
rm -rf "${SYSEXTNAME}"
