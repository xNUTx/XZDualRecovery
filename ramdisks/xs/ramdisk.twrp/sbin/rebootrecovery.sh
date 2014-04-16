#!/sbin/sh
mount /cache
touch /cache/recovery/boot
sync
umount /cache
