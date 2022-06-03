#!/bin/bash
set -xe

script_status="PASS"
MOUNTED_MNT=false
ERR_ECHO() {
    echo "[ERROR] $*"
    script_status="FAILED"
}
ERR_CONT() {
    ERR_ECHO "$*"
}
ERR_EXIT() {
    echo ERR_EXIT
    if [ "$MOUNTED_MNT" = "true" ]; then
        sudo mount /mnt
    fi
    if test $? -eq 0; then
        ERR_ECHO "$*"
        exit 0
    else
        traped_err=$?
        ERR_ECHO "Trapped ERROR: $traped_err"
        exit 0
        #exit $traped_err
    fi
}
#trap ERR_EXIT ERR

usage() {
cat << EOF
usage: $0 /dev/sd-card-device

    -h|--help print this message
EOF
exit 1
}

prepare() {
    echo "check if everything is ready."
    #for file in ${files_to_copy[@]}; do
    #    [ -f $file ] || (ERR_ECHO $file is not ready.; exit 1)
    #done
}

# $1: target device
format_sd() {
    target_size=0
    sudo parted -s "$1" mktable msdos || (echo "parted mktable failed."; usage)

    new_target_size=$((target_size + 256))
    sudo parted -s "$1" mkpart primary fat32 0 "$new_target_size"MiB || (echo "parted mkpart failed."; usage)
    sudo parted -s "$1" set 1 boot on
    target_size=$new_target_size

    new_target_size=$((target_size + 640))
    sudo parted -s "$1" mkpart primary ext4 "$target_size"MiB "$new_target_size"MiB || (echo "parted mkpart failed."; usage)
    target_size=$new_target_size

    new_target_size=$((target_size + 128))
    sudo parted -s "$1" mkpart primary ext4 "$target_size"MiB "$new_target_size"MiB || (echo "parted mkpart failed."; usage)
    target_size=$new_target_size

    sudo parted -s "$1" mkpart primary ext4 "$target_size"MiB "100%" || (echo "parted mkpart failed."; usage)

    sudo mkfs.vfat -F 32 -n BOOT "$1"p1
    yes | sudo mkfs.ext4 -L system "$1"p2
    yes | sudo mkfs.ext4 -L vendor "$1"p3
    yes | sudo mkfs.ext4 -L data "$1"p4
}

# $1: src image.
# $2: target device or partition. e.g. /device/mmcblk0p2
do_dd() {
    # error checking
    [ -e "$1" ] || exit 1
    [ -e "$2" ] || exit 1
    sudo dd if="$1" of="$2" bs=1M
}


# $1: target target device or partition. e.g. /device/mmcblk0
create_sd() {
    [ -z "${1##*mmc*}" ] || (ERR_ECHO "$1" seems not a sdcard.; exit 1)
    format_sd "$1" # TODO
    do_dd out/target/product/rpi3/system.img "$1"p2
    do_dd out/target/product/rpi3/vendor.img "$1"p3

    # copy files
    sudo mount "$1"p1 /mnt
    sudo cp device/brcm/rpi3/boot/* /mnt
    sudo cp kernel/rpi/arch/arm/boot/zImage /mnt
    sudo cp kernel/rpi/arch/arm/boot/dts/bcm2710-rpi-3-b.dtb /mnt
    sudo cp out/target/product/rpi3/ramdisk.img /mnt
    sudo mkdir -p /mnt/overlays
    sudo cp kernel/rpi/arch/arm/boot/dts/overlays/vc4-kms-v3d.dtbo /mnt/overlays
    sudo umount /mnt
}

main() {
    while [ $# -gt 0 ]
    do
        case "$1" in
            -h | --help)
                usage 0
                exit 0
                ;;
            *)
            TARGET_DEVICE="$1"
            ;;
           esac
           shift
    done
    prepare
    create_sd "$TARGET_DEVICE"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
    test "$script_status" == "PASS" || exit 1
fi

