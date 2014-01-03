#!/sbin/busybox sh
#
# Dual Recovery Debugging Tool
#
# Author:
#   [NUT]
#
###########################################################################

set +x
_PATH="$PATH"
export PATH="/sbin:/system/bin:/system/xbin"

# Defining constants, from commandline
EVENTNODE="$1"
DRPATH="$2"
LOGFILE="$3"
LOG="${DRPATH}/${LOGFILE}"

# if the testing requires a reboot because it was destructive, create a donotrun
# file as well to prevent the repeated running of the debug script (bootloop!)
REBOOT="true"

# Kickstarting log
DATETIME=`date +"%d-%m-%Y %H:%M:%S"`
echo "START DEBUG at ${DATETIME}: DR STAGE 2." > ${LOG}

# Z setup
#BOOTREC_CACHE_NODE="/dev/block/mmcblk0p25 b 179 25"
#BOOTREC_CACHE="/dev/block/mmcblk0p25"
BOOTREC_EXTERNAL_SDCARD_NODE="/dev/block/mmcblk1p1 b 179 32"
BOOTREC_EXTERNAL_SDCARD="/dev/block/mmcblk1p1"
BOOTREC_LED_RED="/sys/class/leds/$(busybox ls -1 /sys/class/leds|busybox grep red)/brightness"
BOOTREC_LED_GREEN="/sys/class/leds/$(busybox ls -1 /sys/class/leds|busybox grep green)/brightness"
BOOTREC_LED_BLUE="/sys/class/leds/$(busybox ls -1 /sys/class/leds|busybox grep blue)/brightness"

# Defining functions
ECHOL(){
	_TIME=`busybox date +"%H:%M:%S"`
	busybox echo "$_TIME: $*" >> ${LOG}
	return 0
}
EXECL(){
	_TIME=`busybox date +"%H:%M:%S"`
	busybox echo "$_TIME: $*" >> ${LOG}
	busybox $* 2>&1 >> ${LOG}
	_RET=$?
	busybox echo "$_TIME: RET=$_RET" >> ${LOG}
	return $_RET
}
PEXECL(){
	_TIME=`busybox date +"%H:%M:%S"`
	echo "$_TIME: $*" >> ${LOG}
	$* 2>&1 >> ${LOG}
	_RET=$?
	echo "$_TIME: RET=$_RET" >> ${LOG}
	return $_RET
}
SIGNALLIFE() {
	ECHOL "###########################################################################"
	ECHOL "######                                                               ######"
	ECHOL "######  $*"
	ECHOL "######                                                               ######"
	ECHOL "###########################################################################"
	busybox echo 100 > /sys/class/timed_output/vibrator/enable
	busybox usleep 400000
	busybox echo 100 > /sys/class/timed_output/vibrator/enable
	busybox sleep 1
}
# SETLED [ARG: on or off] [ARG: red color] [ARG: green color] [ARG: blue color]
SETLED() {
        if [ "$1" = "on" ]; then

                ECHOL "Turn on LED R: $2 G: $3 B: $4"
                busybox echo "$2" > ${BOOTREC_LED_RED}
                busybox echo "$3" > ${BOOTREC_LED_GREEN}
                busybox echo "$4" > ${BOOTREC_LED_BLUE}

        else

                ECHOL "Turn off LED"
                busybox echo "0" > ${BOOTREC_LED_RED}
                busybox echo "0" > ${BOOTREC_LED_GREEN}
                busybox echo "0" > ${BOOTREC_LED_BLUE}

        fi
}
# DRGETPROP [ARG: propertyname]
DRGETPROP() {

        # Get the property from getprop
        PROP=`/system/bin/getprop $*`

        if [ "$PROP" = "" ]; then

                # If it's empty, see if what was requested was a XZDR.prop value!
                PROP=`busybox grep "$*" ${DRPATH}/XZDR.prop | busybox awk -F'=' '{ print $NF }'`

        fi
        if [ "$PROP" = "" ]; then

                # If it still is empty, try to get it from the build.prop
                PROP=`busybox grep "$*" /system/build.prop | busybox awk -F'=' '{ print $NF }'`

        fi

        busybox echo $PROP

}
# TAGSLEEP [ARG: Total time in seconds] [ARG: Loop increments]
TAGSLEEP() {
	i="0"
	while [ $i -lt $1 ]; do
		EXECL sleep $2
		i=$[$i+$2]
	done
}

# if the testing requires a reboot because it was destructive, create a donotrun
# file as well to prevent the repeated running of the debug script (bootloop!)
if [ "$REBOOT" = "true" ]; then
	busybox touch ${DRPATH}/donotrun
fi

SETLED on 255 255 255

ECHOL "Checking device model..."
MODEL=$(DRGETPROP ro.product.model)
VERSION=$(DRGETPROP ro.build.id)
PHNAME=$(DRGETPROP ro.semc.product.name)

SIGNALLIFE "Model found: $MODEL ($PHNAME - $VERSION)"

###########################################################################
#
# START DEBUG SCRIPT
#
###########################################################################

SIGNALLIFE "Get all defined properties"

PEXECL /system/bin/getprop

SIGNALLIFE "Get all mounts currently active"

EXECL mount

SIGNALLIFE "Get a baseline processlist"

EXECL ps wlT

SIGNALLIFE "Initialize time_daemon"

# Initialize system clock.
ECHOL "Europe/Amsterdam timezone..."
EXECL export TZ=GMT+1
ECHOL "Start time_daemon..."
/system/bin/time_daemon &
EXECL sleep 2
ECHOL "Kill time_daemon..."
EXECL pkill -f /system/bin/time_daemon

TAGSLEEP 90 5

SIGNALLIFE "Start killing running services..."

# Stop init services.
for SVCRUNNING in $(/system/bin/getprop | busybox grep -E '^\[init\.svc\..*\]: \[running\]'); do

	SVCNAME=$(busybox expr ${SVCRUNNING} : '\[init\.svc\.\(.*\)\]:.*')

	SIGNALLIFE "Stopping ${SVCNAME}"

	EXECL ps wlT

	PEXECL stop ${SVCNAME}

	EXECL sleep 2

	EXECL ps wlT

	TAGSLEEP 50 5

done

EXECL kill -9 $(busybox ps | busybox grep rmt_storage | busybox grep -v "grep" | busybox awk -F' ' '{print $1}')

EXECL sleep 2

EXECL ps wlT

TAGSLEEP 50 5

SIGNALLIFE "Checking file locks left on phone..."

EXECL lsof | grep "/system"
EXECL lsof | grep "/cache"
EXECL lsof | grep "/data"

EXECL mount

EXECL umount /system
EXECL umount /cache
EXECL umount /data

EXECL mount

###########################################################################
#
# END DEBUG SCRIPT
#
###########################################################################

# Turn on green LED as a visual cue
SETLED on 0 255 0

sleep 2

# Turn off LED
SETLED off

ECHOL "Remount / ro..."
mount -o remount,ro rootfs /

if [ "$REBOOT" = "true" ]; then
	ECHOL "Rebooting to return to normal boot mode..."
else
	ECHOL "Returning to normal boot mode..."
fi

# Ending log
DATETIME=`busybox date +"%d-%m-%Y %H:%M:%S"`
busybox echo "STOP DEBUG at ${DATETIME}: DR STAGE 2." >> ${LOG}

# Unmount SDCard1
busybox umount -l /storage/sdcard1

# Return path variable to default
busybox export PATH="${_PATH}"

# if the testing requires a reboot because it was destructive, create a donotrun
# file as well to prevent the repeated running of the debug script (bootloop!)
if [ "$REBOOT" = "true" ]; then
	exec busybox reboot
else
	# Continue booting
	exec /system/bin/chargemon.stock
fi
