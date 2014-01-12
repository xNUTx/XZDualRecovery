#!/sbin/busybox sh

# Remap boot and FOTAKernel for LK setups in recovery

# Remove existing nodes for boot and FOTA
rm -f /dev/block/mmcblk0p14
rm -f /dev/block/mmcblk0p16

# Create remapped nodes
mknod -m 600 /dev/block/mmcblk0p14 b 179 16
mknod -m 600 /dev/block/mmcblk0p16 b 179 14
