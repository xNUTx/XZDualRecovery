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

if [ "$ROMVER" = "14.2.A.0.290" -o "$ROMVER" = "14.2.A.1.136" -o "$ROMVER" = "14.2.A.1.114" -o "$ROMVER" = "14.3.A.0.681" ]; then

	cp /tmp/disableric /system/xbin/
	chmod 755 /system/xbin/disableric

fi

exit 0
