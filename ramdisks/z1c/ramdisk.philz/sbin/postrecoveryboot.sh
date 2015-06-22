#!/sbin/sh

if [ "$(mount | grep '/storage/sdcard1' | wc -l)" = "1" ]; then
	umount -l /storage/sdcard1
	return $?
fi

SYSTEM=$(/sbin/busybox find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system")

# Thanks to McBane87 @ XDA for the initial fix which is the base of this snippet of code.
/sbin/umount /system
/sbin/busybox blockdev --setrw $SYSTEM

/sbin/e2fsck -pcf $SYSTEM
if [ "$?" -ne "0" ]; then

	return $?

fi

/sbin/mount -o ro /system
/sbin/mount -o remount,rw /system
/sbin/umount /system

return 0
