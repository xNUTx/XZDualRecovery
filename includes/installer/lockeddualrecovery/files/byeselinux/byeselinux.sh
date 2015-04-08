#!/data/local/tmp/recovery/busybox sh
######
#
# Part of byeselinux, created originally by zxz0O0, modified for use in XZDualRecovery by [NUT]
#

BUSYBOX="/data/local/tmp/recovery/busybox"

if [ ! -f /data/local/tmp/recovery/byeselinux.ko ]; then
	echo "Error patching kernel module. File not found."
	exit 1
fi

if [ ! -f /data/local/tmp/recovery/modulecrcpatch ]; then
	echo "Error: modulecrcpatch not found"
	exit 1
fi

$BUSYBOX chmod 777 /data/local/tmp/recovery/modulecrcpatch
for module in /system/lib/modules/*.ko; do
	/data/local/tmp/recovery/modulecrcpatch $module /data/local/tmp/recovery/byeselinux.ko 1> /dev/null
done

$BUSYBOX mount -o remount,rw /system
if [ "$?" != "0" ]; then
        echo "Remount R/W failed, installing byeselinux aborted!"
        exit 1
fi

if [ -f "/system/lib/modules/mhl_sii8620_8061_drv_orig.ko" ]; then
	$BUSYBOX rm -f /system/lib/modules/mhl_sii8620_8061_drv.ko
	$BUSYBOX cp /system/lib/modules/mhl_sii8620_8061_drv_orig.ko /system/lib/modules/mhl_sii8620_8061_drv.ko
fi

$BUSYBOX cp /data/local/tmp/recovery/byeselinux.ko /system/lib/modules/byeselinux.ko
$BUSYBOX chmod 644 /system/lib/modules/byeselinux.ko

exit 0
