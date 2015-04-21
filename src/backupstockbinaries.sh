#!/sbin/sh

if [ ! -f "/system/bin/mr.stock" ]; then

	/sbin/busybox mv /system/bin/mr /system/bin/mr.stock

fi

if [ ! -f "/system/bin/chargemon.stock" -a "$(/sbin/busybox head -n 1 /system/bin/chargemon)" != '#!/system/bin/sh' ]; then

	/sbin/busybox mv /system/bin/chargemon /system/bin/chargemon.stock

fi
