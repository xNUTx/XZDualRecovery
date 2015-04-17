#!/tmp/busybox sh

KERNELPARTITION=$(find /dev/block/platform/msm_sdcc.1/by-name \( -iname "boot" -o -iname "kernel" \))

/tmp/busybox dd if=/tmp/boot.img of=$KERNELPARTITION

return $?
