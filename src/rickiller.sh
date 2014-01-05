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
	$BUSYBOX mount -o remount,rw rootfs /

	# Move the ric binary out of the way...
	$BUSYBOX mv ${RICPATH} ${RICPATH}c

	$BUSYBOX touch /tmp/killedric

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

fi

ECHOL "Script finished, exitting!"

$BUSYBOX mount -o remount,ro rootfs /

exit 0
