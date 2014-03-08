#!/tmp/busybox sh

if [ ! -f "/system/bin/mr.stock" ]; then

	/tmp/busybox mv /system/bin/mr /system/bin/mr.stock

fi
