#!/sbin/busybox sh

# Remap boot and FOTAKernel for LK setups in recovery

# Remove existing nodes for boot and FOTA
rm -f /dev/block/mmcblk0p17
rm -f /dev/block/mmcblk0p23

# Create remapped nodes
mknod -m 600 /dev/block/mmcblk0p17 b 179 23
mknod -m 600 /dev/block/mmcblk0p23 b 179 17

