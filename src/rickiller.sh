#!/system/bin/sh

#####
#
# RIC Killer, it will exit as soon as it found and killed it!
#
# This is the one as part of the XZDualRecovery installation
# It has been modified to work with the securityfs 'sony_ric' setting
# on fully secured JB 4.3 installations...
#
# Author: [NUT] on XDA
#

BUSYBOX=$1

LOG="/data/local/tmp/rickiller.log"

echo "" > $LOG

ECHOL(){
	_TIME=`$BUSYBOX date +"%H:%M:%S"`
	echo "$_TIME: $*" >> ${LOG}
	return 0
}

EXECL(){
	_TIME=`$BUSYBOX date +"%H:%M:%S"`
	echo "$_TIME: $*" >> ${LOG}
	$BUSYBOX $* 2>&1 >> ${LOG}
	_RET=$?
	echo "$_TIME: RET=$_RET" >> ${LOG}
	return ${_RET}
}


DRGETPROP() {

        # Get the property from getprop
        PROP=`/system/bin/getprop $*`

        if [ "$PROP" = "" ]; then

                # If it still is empty, try to get it from the build.prop
                PROP=`$BUSYBOX grep "$*" /system/build.prop | $BUSYBOX awk -F'=' '{ print $NF }'`

        fi

        echo $PROP

}

# Do something on filechange, takes 2 arguments:
# monitorFileChange /path/to/file_or_directory "command to be executed"
# Make sure you quote the command if it has spaces.
# The command can also be a script function, no need to call in a secondary script!
onFileChange() {

	ECHOL "onFileChange running"
	EXECL stat -t $1
	LTIME=`$BUSYBOX stat -t $1`

	while true
	do

		EXECL stat -t $1
		ATIME=`$BUSYBOX stat -t $1`

		if [ "$ATIME" != "$LTIME" ]; then

			ECHOL "Running: $2"
			$2
			return 0
			# LTIME=$ATIME

   		fi

   		$BUSYBOX usleep 100000

	done

}

# This will only run when a 4.3 ROM has been found with the securityfs mount active, for 4.2.2 and earlier this fix has no purpose.
actOnSecFSMount() {

	ECHOL "actOnSecFSMount running"

	ECHOL "$(DRGETPROP ro.build.version.release) and $($BUSYBOX grep "mount securityfs securityfs /sys/kernel/security" /init.sony-platform.rc | $BUSYBOX wc -l)"

	if [ "$(DRGETPROP ro.build.version.release)" = "4.3" -a $($BUSYBOX grep "mount securityfs securityfs /sys/kernel/security" /init.sony-platform.rc | $BUSYBOX wc -l) -eq 1 ]; then

		ECHOL "4.3 ROM, with securityfs, lets do it!"
		onFileChange /sys/kernel/security disableRIC

	fi

}

disableRIC() {

	ECHOL "disableRIC running"

	# As it's only useful to disable it once it has been enabled, test for the value to change
	if [ ! -f "/sys/kernel/security/sony_ric/enable" ]; then

		ECHOL "/sys/kernel/security/sony_ric/enable has vanished or simply does not exist, disableRIC is stopping now!"
		return 0

	elif [ -f "/sys/kernel/security/sony_ric/enable" ]; then
		ECHOL "/sys/kernel/security/sony_ric/enable available, changing now!"
		echo 0 > /sys/kernel/security/sony_ric/enable
		EXECL cat /sys/kernel/security/sony_ric/enable
		return 0
	else
		$BUSYBOX usleep 100000
		disableRIC
	fi

}

RicIsKilled() {
        if [ -f "/tmp/killedric" ]; then
                return 0
        else
                return 1
        fi
}

INITIALRICCHECK=$(ps | $BUSYBOX grep "bin/ric" | $BUSYBOX grep -v "grep" | $BUSYBOX awk '{ print $NF }')
if [ "$INITIALRICCHECK" = "" ]; then

	# RIC is not running yet, so we can do to it whatever we want!
	# Lets find it first...
	RICPATH="/sbin/ric" # assuming it exists on the ramdisk

	if [ -e "/system/bin/ric" ]; then # and then checking if it exists in the ROM...

		RICPATH="/system/bin/ric"

	fi

	# Just to make sure the rootfs has been remounted writable. It should already though...
	$BUSYBOX mount -o remount,rw /

	# Move the ric binary out of the way...
	$BUSYBOX mv ${RICPATH} ${RICPATH}c

	$BUSYBOX touch /tmp/killedric

	# lets kickstart the security demolisher :)
	actOnSecFSMount

fi

if [ ! -f "/tmp/killedric" ]; then

	until RicIsKilled
	do

		RICPATH=$(ps | $BUSYBOX grep "bin/ric" | $BUSYBOX grep -v "grep" | $BUSYBOX awk '{ print $NF }')

		if [ "$RICPATH" != "" ]; then

			$BUSYBOX mount -o remount,rw / && mv ${RICPATH} ${RICPATH}c && $BUSYBOX pkill -f ${RICPATH}

		else

			$BUSYBOX touch /tmp/killedric

		fi

		$BUSYBOX sleep 2

	done

	actOnSecFSMount

fi

ECHOL "Script finished, exitting!"

exit 0
