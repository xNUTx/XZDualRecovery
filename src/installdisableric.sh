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

######
#
# No, there is nothing missing ;) I have moved the work the disableric script did to the chargemon script.
#

ANDROIDVER=`echo "$(DRGETPROP ro.build.version.release) 5.0.0" | awk '{if ($2 != "" && $1 >= $2) print "lollipop"; else print "other"}'`
if [ "$ANDROIDVER" = "lollipop" ]; then
	# Part of byeselinux, requisit for Lollipop based firmwares
	chmod 755 /tmp/sysrw.sh
	/tmp/sysrw.sh
	chmod 755 /tmp/byeselinux.sh
	/tmp/byeselinux.sh
fi

exit 0
