#!/sbin/busybox sh
######
#
# Part of byeselinux, created originally by zxz0O0, modified for use in XZDualRecovery by [NUT]
#
# Flashable version
#

BUSYBOX="/sbin/busybox"

$BUSYBOX chmod 777 /tmp/modulecrcpatch
/tmp/modulecrcpatch /tmp/byeselinux.ko /tmp/byeselinux.ko 1> /dev/null

$BUSYBOX cp /tmp/byeselinux.ko /system/lib/modules/byeselinux.ko
$BUSYBOX chmod 644 /system/lib/modules/byeselinux.ko

exit 0
