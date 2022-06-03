#!/bin/bash
# refer to https://github.com/android-rpi/device_brcm_rpi3
ROOT_DIR="$PWD"
ERR_EXIT() {
    if test $? -eq 0; then
        ERR_ECHO "$*"
        cd $ROOT_DIR
        exit 1
    else
        traped_err=$?
        ERR_ECHO "Trapped ERROR: $traped_err"
        cd $ROOT_DIR
        exit $traped_err
    fi
}
trap ERR_EXIT ERR

pushd kernel/rpi || exit 1
    ARCH=arm scripts/kconfig/merge_config.sh arch/arm/configs/bcm2709_defconfig kernel/configs/android-base.config kernel/configs/android-recommended.config
    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make zImage -j 10
    ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make dtbs -j 10
popd
