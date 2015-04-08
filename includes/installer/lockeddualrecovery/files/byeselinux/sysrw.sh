#!/data/local/tmp/recovery/busybox sh
######
#
# Part of byeselinux, created originally by zxz0O0, modified for use in XZDualRecovery by [NUT]
#

BUSYBOX="/data/local/tmp/recovery/busybox"

$BUSYBOX mount -o remount,rw /system 2> /dev/null
if [ "$?" = "0" ]; then
	echo "No system mount security"
	exit 0
fi

if [ ! -f /data/local/tmp/recovery/wp_mod.ko ]; then
	echo "Error patching kernel module. File not found."
	exit 1
fi

if [ ! -f /data/local/tmp/recovery/modulecrcpatch ]; then
	echo "Error: modulecrcpatch not found"
	exit 1
fi

$BUSYBOX chmod 777 /data/local/tmp/recovery/modulecrcpatch
for module in /system/lib/modules/*.ko; do
        /data/local/tmp/recovery/modulecrcpatch $module /data/local/tmp/recovery/wp_mod.ko 1> /dev/null
done

$BUSYBOX insmod /data/local/tmp/recovery/wp_mod.ko

$BUSYBOX mount -o remount,rw /system 2> /dev/null
if [ "$?" != "0" ]; then
	echo "Remount R/W failed!"
	exit 1
fi

exit 0
