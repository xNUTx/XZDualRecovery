#!/sbin/sh

DRPATH="/storage/sdcard1/XZDualRecovery"

if [ ! -d "/storage/sdcard1/XZDualRecovery" ]; then
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

ANDROIDVER=`echo "$(DRGETPROP ro.build.version.release) 5.0.0" | awk '{if ($2 != "" && $1 >= $2) print "lollipop"; else print "other"}'`

if [ "$ANDROIDVER" = "lollipop" ]; then
	mkdir /system/app/NDRUtils
	chmod 755 /system/app/NDRUtils
	cp /data/local/tmp/recovery/NDRUtils.apk /system/app/NDRUtils/
	chmod 644 /system/app/NDRUtils/NDRUtils.apk
else
	cp /data/local/tmp/recovery/NDRUtils.apk /system/app/
	chmod 644 /system/app/NDRUtils.apk
fi

exit 0
