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

BUSYBOX="/sbin/busybox"

LOG="/data/local/tmp/rickiller.log"

_PATH="$PATH"

export PATH=".:/system/xbin:/system/bin:/sbin"

$BUSYBOX echo -n "" > $LOG

ECHOL(){
	_TIME=`$BUSYBOX date +"%H:%M:%S"`
	$BUSYBOX echo "$_TIME: $*" >> $LOG
	return 0
}

EXECL(){
	_TIME=`$BUSYBOX date +"%H:%M:%S"`
	$BUSYBOX echo "$_TIME: $*" >> $LOG
	$BUSYBOX $* 2>&1 >> $LOG
	_RET=$?
	$BUSYBOX echo "$_TIME: RET=$_RET" >> $LOG
	return $_RET
}

DRGETPROP() {

        # Get the property from getprop
        PROP=`/system/bin/getprop $*`

        if [ "$PROP" = "" ]; then

                # If it still is empty, try to get it from the build.prop
                PROP=`$BUSYBOX grep "$*" /system/build.prop | $BUSYBOX awk -F'=' '{ print $NF }'`

        fi

        $BUSYBOX echo $PROP

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

# RIC is not running yet, so we can do to it whatever we want!
# Lets find it first...
RICPATH="/sbin/ric" # assuming it exists on the ramdisk

if [ -e "/system/bin/ric" ]; then # and then checking if it exists in the ROM...

	RICPATH="/system/bin/ric"

fi

# Just to make sure the rootfs has been remounted writable. It should already though...
$BUSYBOX mount -o remount,rw /
$BUSYBOX mount -o remount,rw /system

# Replace the ric binary...
EXECL rm -rf $RICPATH

EXECL touch $RICPATH
$BUSYBOX echo "#!/system/bin/sh" >> $RICPATH
$BUSYBOX echo "while :" >> $RICPATH
$BUSYBOX echo "do" >> $RICPATH
$BUSYBOX echo 'if [ -f "/sys/kernel/security/sony_ric/enable" ]; then' >> $RICPATH
$BUSYBOX echo "echo 0 > /sys/kernel/security/sony_ric/enable" >> $RICPATH
$BUSYBOX echo "fi" >> $RICPATH
$BUSYBOX echo 'if [ "$(busybox blockdev --getro $(find /dev/block/platform/msm_sdcc.1/by-name/ -iname system))" = "1" ]; then' >> $RICPATH
$BUSYBOX echo "busybox blockdev --setrw $(find /dev/block/platform/msm_sdcc.1/by-name/ -iname system)" >> $RICPATH
$BUSYBOX echo "fi" >> $RICPATH
$BUSYBOX echo "sleep 60" >> $RICPATH
$BUSYBOX echo "done" >> $RICPATH

EXECL chmod 755 $RICPATH

EXECL touch /tmp/killedric

ECHOL "Script finished, exitting!"

$BUSYBOX mount -o remount,ro /system
$BUSYBOX mount -o remount,ro /

PATH="$_PATH"

exit 0
