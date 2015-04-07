#!/drbin/busybox sh
######
#
# Part of byeselinux, created originally by zxz0O0, modified for use in XZDualRecovery by [NUT]
#
# Flashable version
#

BUSYBOX="/drbin/busybox"

$BUSYBOX cp /sbin/modulecrcpatch /drbin/modulecrcpatch
$BUSYBOX chmod 755 /drbin/modulecrcpatch
$BUSYBOX cp /sbin/byeselinux.ko /drbin/byeselinux.ko
$BUSYBOX chmod 644 /drbin/byeselinux.ko

/drbin/modulecrcpatch /drbin/byeselinux.ko /drbin/byeselinux.ko
$BUSYBOX cp /sbin/byeselinux.ko /system/lib/modules/byeselinux.ko
$BUSYBOX chmod 644 /system/lib/modules/byeselinux.ko

exit 0
