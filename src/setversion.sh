#!/sbin/busybox sh

BUSYBOX="/sbin/busybox"

LOGDIR="XZDualRecovery"
DRPATH="/storage/sdcard1/${LOGDIR}"

if [ ! -d "${DRPATH}" ]; then
	DRPATH="/cache/${LOGDIR}"
fi
if [ ! -d "${DRPATH}" ]; then
	DRPATH="/external_sd/${LOGDIR}"
fi

# Find the gpio-keys node, to listen on the right input event
gpioKeysSearch() {
        for INPUTUEVENT in `${BUSYBOX} find /sys/devices \( -path "*gpio*" -path "*keys*" -a -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

                INPUTDEV=$(${BUSYBOX} grep "DEVNAME=" ${INPUTUEVENT} | ${BUSYBOX} sed 's/DEVNAME=//')

                if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
                        echo "/dev/${INPUTDEV}"
                        return 0
                fi

        done
	return 1
}

# Find the power key node, to listen on the right input event
pwrkeySearch() {
        # pm8xxx (xperia Z and similar)
        for INPUTUEVENT in `${BUSYBOX} find /sys/devices \( -path "*pm8xxx*" -path "*pwrkey*" -a -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

                INPUTDEV=$(${BUSYBOX} grep "DEVNAME=" ${INPUTUEVENT} | ${BUSYBOX} sed 's/DEVNAME=//')

                if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
                        echo "/dev/${INPUTDEV}"
			return 0
                fi

        done
        # qpnp_pon (xperia Z1 and similar)
        for INPUTUEVENT in `${BUSYBOX} find $(${BUSYBOX} find /sys/devices/ -name "name" -exec ${BUSYBOX} grep -l "qpnp_pon" {} \; | ${BUSYBOX} awk -F '/' 'sub(FS $NF,x)') \( -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

                INPUTDEV=$(${BUSYBOX} grep "DEVNAME=" ${INPUTUEVENT} | ${BUSYBOX} sed 's/DEVNAME=//')

                if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
                        echo "/dev/${INPUTDEV}"
			return 0
                fi

        done
	return 1
}

DRGETPROP() {

        VAR=`${BUSYBOX} grep "$*" /tmp/dr.prop | ${BUSYBOX} awk -F'=' '{ print $1 }'`
        PROP=`${BUSYBOX} grep "$*" /tmp/dr.prop | ${BUSYBOX} awk -F'=' '{ print $NF }'`

	if [ "$VAR" = "" -a "$PROP" = "" ]; then

		# If it's empty, see if what was requested was a XZDR.prop value!
        	VAR=`${BUSYBOX} grep "$*" ${DRPATH}/XZDR.prop | awk -F'=' '{ print $1 }'`
        	PROP=`${BUSYBOX} grep "$*" ${DRPATH}/XZDR.prop | awk -F'=' '{ print $NF }'`

        	if [ "$VAR" = "" -a "$PROP" = "" ]; then

        	        # If it still is empty, try to get it from the build.prop
                	VAR=`${BUSYBOX} grep "$*" /system/build.prop | awk -F'=' '{ print $1 }'`
                	PROP=`${BUSYBOX} grep "$*" /system/build.prop | awk -F'=' '{ print $NF }'`

        	fi

	fi

	if [ "$VAR" != "" ]; then
        	echo $PROP
	else
		echo "null"
	fi

}
DRSETPROP() {

        # We want to set this only if the XZDR.prop file exists...
        if [ ! -f "${DRPATH}/XZDR.prop" ]; then
                return 0
        fi

        PROP=$(DRGETPROP $1)

        if [ "$PROP" != "null" ]; then
                ${BUSYBOX} sed -i 's|'$1'=[^ ]*|'$1'='$2'|' ${DRPATH}/XZDR.prop
        else
                ${BUSYBOX} echo "$1=$2" >> ${DRPATH}/XZDR.prop
        fi
        return 0

}

DRSETPROP dr.xzdr.version $(DRGETPROP version)
DRSETPROP dr.release.type $(DRGETPROP release)

#echo "Trying to find and update the gpio-keys event node."
GPIOINPUTDEV="$(gpioKeysSearch)"
#echo "Found and will be using ${GPIOINPUTDEV}!"
DRSETPROP dr.gpiokeys.node ${GPIOINPUTDEV}

#echo "Trying to find and update the power key event node."
PWRINPUTDEV="$(pwrkeySearch)"
#echo "Found and will be monitoring ${PWRINPUTDEV}!"
DRSETPROP dr.pwrkey.node ${PWRINPUTDEV}

if [ "$(DRGETPROP dr.keep.byeselinux)" != "true" ]; then
	#echo "Will unload byeselinux every boot"
	DRSETPROP dr.keep.byeselinux false
else
	DRSETPROP dr.keep.byeselinux true
fi

exit 0
