#!/sbin/sh

DRPATH="/storage/sdcard1/XZDualRecovery"

if [ !-d "/storage/sdcard1/XZDualRecovery" ]; then
	DRPATH="/cache/XZDualRecovery"
fi

DRGETPROP() {

	# If it's empty, see if what was requested was a XZDR.prop value!
        PROP=`grep "$*" ${DRPATH}/XZDR.prop | awk -F'=' '{ print $NF }'`

        if [ "$PROP" = "" ]; then

                # If it still is empty, try to get it from the build.prop
                PROP=`grep "$*" /system/build.prop | awk -F'=' '{ print $NF }'`

        fi

        echo $PROP

}

ROMVER=$(DRGETPROP ro.build.id)

if [ -e "/system/.XZDualRecovery/init.rc" ]; then

	if [ "$(grep '/sys/kernel/security/sony_ric/enable' /system/.XZDualRecovery/init.* | wc -l)" = "1" ]; then

		cp /tmp/disableric /system/xbin/
		chmod 755 /system/xbin/disableric

	fi

else

	if [ "$ROMVER" = "14.2.A.0.290"   -o "$ROMVER" = "14.2.A.1.136"   -o "$ROMVER" = "14.2.A.1.114" -o "$ROMVER" = "14.3.A.0.681"   -o \
	     "$ROMVER" = "14.3.A.0.757"   -o "$ROMVER" = "17.1.1.A.0.402" -o "$ROMVER" = "14.4.A.0.108" -o "$ROMVER" = "17.1.2.A.0.323" -o \
	     "$ROMVER" = "17.1.2.A.0.314" -o "$ROMVER" = "23.0.1.A.0.167" -o "$ROMVER" = "23.0.1.A.3.9" -o "$ROMVER" = "23.0.1.A.4.30"  -o \
	     "$ROMVER" = "23.0.1.A.4.44"  -o "$ROMVER" = "14.4.A.0.157"   -o "$ROMVER" = "23.0.A.2.93"  -o "$ROMVER" = "23.0.A.2.98"    -o \
	     "$ROMVER" = "23.0.A.2.105"   -o "$ROMVER" = "23.0.1.A.5.77"  -o "$ROMVER" = "23.0.A.2.106" -o "$ROMVER" = "23.0.F.1.74" -o \
	     "$ROMVER" = "23.1.A.0.690"   -o "$ROMVER" = "23.1.A.0.726" ]; then

		cp /tmp/disableric /system/xbin/
		chmod 755 /system/xbin/disableric

	fi

fi

ANDROIDVER=`echo "$(DRGETPROP ro.build.version.release) 5.0.0" | awk '{if ($2 != "" && $1 >= $2) print "lollipop"; else print "other"}'`
if [ "$ANDROIDVER" = "lollipop" ]; then
	# Part of byeselinux, requisit for Lollipop based firmwares
	chmod 755 /tmp/sysrw.sh
	/tmp/sysrw.sh
	chmod 755 /tmp/byeselinux.sh
	/tmp/byeselinux.sh
fi

exit 0
