#!/sbin/busybox sh
######
#
# Part of byeselinux, created originally by zxz0O0, modified for use in XZDualRecovery by [NUT]
#
# Flashable version
#

BUSYBOX="/sbin/busybox"

$BUSYBOX chmod 777 /tmp/modulecrcpatch
for module in /system/lib/modules/*.ko; do
	/tmp/modulecrcpatch $module /tmp/byeselinux.ko 1> /dev/null
done

$BUSYBOX cp /tmp/byeselinux.ko /system/lib/modules/byeselinux.ko
$BUSYBOX chmod 644 /system/lib/modules/byeselinux.ko

exit 0
