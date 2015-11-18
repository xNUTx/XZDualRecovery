#!/sbin/busybox sh
######
#
# Part of byeselinux, created originally by zxz0O0, modified for use in XZDualRecovery by [NUT]
#
# Flashable version
#

BUSYBOX="/sbin/busybox"

if [ -e "/system/.XZDualRecovery/init.rc" -a "$($BUSYBOX grep '/sys/kernel/security/sony_ric/enable' /system/.XZDualRecovery/init.* | $BUSYBOX wc -l)" != "0" ]; then

	$BUSYBOX chmod 777 /tmp/modulecrcpatch
	for module in /system/lib/modules/*.ko; do
		/tmp/modulecrcpatch $module /tmp/wp_mod.ko 1> /dev/null
	done

	$BUSYBOX cp /tmp/wp_mod.ko /system/lib/modules/wp_mod.ko
	$BUSYBOX chmod 644 /system/lib/modules/wp_mod.ko

fi

exit 0
