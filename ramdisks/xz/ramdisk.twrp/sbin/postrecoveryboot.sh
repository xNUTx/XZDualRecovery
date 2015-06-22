#!/sbin/sh

if [ "$(mount | grep '/storage/sdcard1' | wc -l)" = "1" ]; then
	umount -l /storage/sdcard1
	return $?
fi

return 0
