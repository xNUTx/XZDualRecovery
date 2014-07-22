#!/system/bin/sh

#patch kernel module vermagic by zxz0O0

if [ ! -f /data/local/tmp/wp_mod.ko ]; then
	echo "Error patching kernel module. File not found."
	exit 1
fi

kernelver=`/data/local/tmp/busybox cat /proc/version | /data/local/tmp/busybox cut -d' ' -f3`
echo "Kernel version is $kernelver"

if [ ! "$kernelver" = "3.4.0-perf-ge4322cd" ]; then
	echo "Version does not match 3.4.0-perf-ge4322cd, needs patching..."
	echo "$kernelver" | dd of=/data/local/tmp/wp_mod.ko conv=notrunc obs=476 seek=1 ibs=${#kernelver} count=1
	echo "Kernel module patched."
else
	echo "Version matches. No patching needed."
fi

if [ -f /data/local/tmp/modulecrcpatch ]; then
	/data/local/tmp/modulecrcpatch /system/lib/modules/scsi_wait_scan.ko /data/local/tmp/wp_mod.ko
fi

exit