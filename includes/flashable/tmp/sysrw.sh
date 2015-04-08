#!/sbin/busybox sh
######
#
# Part of byeselinux, created originally by zxz0O0, modified for use in XZDualRecovery by [NUT]
#
# Flashable version
#

BUSYBOX="/sbin/busybox"

$BUSYBOX chmod 777 /tmp/modulecrcpatch
/tmp/modulecrcpatch /tmp/wp_mod.ko /tmp/wp_mod.ko 1> /dev/null

$BUSYBOX cp /tmp/wp_mod.ko /system/lib/modules/wp_mod.ko
$BUSYBOX chmod 644 /system/lib/modules/wp_mod.ko

exit 0
