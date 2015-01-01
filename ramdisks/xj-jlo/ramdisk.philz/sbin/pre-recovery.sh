# Writes either 'recovery' or 'bootloader' to the file.
busybox echo $@ > /cache/recovery/boot
busybox sync
