#!/sbin/sh

if [ ! -f "/system/bin/mr.stock" ]; then

	/sbin/busybox mv /system/bin/mr /system/bin/mr.stock

fi

if [ ! -f "/system/bin/chargemon.stock" ]; then

	/sbin/busybox mv /system/bin/chargemon /system/bin/chargemon.stock

fi

# Just to make sure it's not a script
CHARGEMON=`/sbin/busybox head -n 1 /system/bin/chargemon.stock`

if [ "${CHARGEMON}" = "#!/system/bin/sh" ]; then

	# It is, lets replace it with the correct binary!
	MODEL=`/system/bin/getprop ro.product.model`
	if [ "${MODEL}" = "C6602" -o "${MODEL}" = "C6603" -o "${MODEL}" = "SO-02E" ]; then
		/sbin/busybox cp /tmp/chargemon.c660x /system/bin/chargemon.stock
		/sbin/busybox chmod 755 /system/bin/chargemon.stock
	elif [ "${MODEL}" = "C6502" -o "${MODEL}" = "C6503" -o "${MODEL}" = "C6506" ]; then
		/sbin/busybox cp /tmp/chargemon.c650x /system/bin/chargemon.stock
		/sbin/busybox chmod 755 /system/bin/chargemon.stock
	elif [ "${MODEL}" = "C6902" -o "${MODEL}" = "C6903" -o "${MODEL}" = "C6906" -o "${MODEL}" = "C6943" ]; then
		/sbin/busybox cp /tmp/chargemon.c690x /system/bin/chargemon.stock
		/sbin/busybox chmod 755 /system/bin/chargemon.stock
	fi

fi
