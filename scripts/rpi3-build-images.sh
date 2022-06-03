#!/bin/bash
# refer to https://github.com/android-rpi/device_brcm_rpi3
usage() {
cat << EOF
usage: source $0
Because I would like to keep the helper function defined by envsetup.sh
EOF
exit 1
}

[ "${BASH_SOURCE[0]}" != "$0" ] || usage
echo \${BASH_SOURCE[0]} : ${BASH_SOURCE[0]}
echo \$0 : $0

source build/envsetup.sh
lunch rpi3-eng
make -j 10 ramdisk systemimage vendorimage
