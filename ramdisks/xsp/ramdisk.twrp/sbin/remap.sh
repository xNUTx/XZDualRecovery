#!/sbin/busybox sh

# Remap boot and FOTAKernel for LK setups in recovery

# Remove existing nodes for boot and FOTA
rm -f /dev/block/mmcblk0p2
rm -f /dev/block/mmcblk0p11

# Create remapped nodes
mknod -m 600 /dev/block/mmcblk0p2 b 179 11
mknod -m 600 /dev/block/mmcblk0p11 b 179 2

