#!/system/.xzdr/bin/sh
#
# Multi Recovery for many Sony Xperia devices!
#
# Authors:
#   [NUT], AngelBob, Olivier and shoey63
#
# - Thanks go to DooMLoRD for the keycodes and a working example!
# - My gratitude also goes out to Androxyde for his sometimes briliant
#   ideas to simplify things while writing the scripts!
#
###########################################################################

set +x
PATH="/system/.xzdr/bin:/system/.xzdr/sbin:/sbin"

# Settings and log folder
export XZDRFolder="XZDualRecovery"
# Logfile name
export XZDRLogfile="XZDualRecovery.log"

# Setup temporary environment
mount -o remount,rw rootfs /
if [ ! -d "/tmp" ]; then

	mkdir /tmp
	mount -t tmpfs tmpfs /tmp

fi
mkdir /tmp/XZDualRecovery
export XZDRLOGFILE="/tmp/XZDualRecovery.log"

# Kickstarting log
DATETIME=`busybox date +"%d-%m-%Y %H:%M:%S"`
echo "START Dual Recovery at ${DATETIME}: STAGE 1." > $XZDRLOGFILE

# Mount SDCard1 if possible and set up, /cache is the alternative location
mountsdcard

# Set environment
export XZDRLOGFILE="$XZDRPATH/XZDualRecovery.log"

# https://github.com/android/platform_system_core/commit/e18c0d508a6d8b4376c6f0b8c22600e5aca37f69
# The busybox in all of the recoveries may not have been patched to take this in account.
blockdev --setrw $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system")

# As a precaution, give users a way out. This works best if the user has an external sdcard.
if [ -f "$XZDRPATH/donotrun" ]; then

	writelog "Exitting by DNR file.";

	exit2bin

fi

# Setting up or restoring basic XZDR functionality
xzdrinit

# Debugging substitution, for ease of use in debugging specific user problems
if [ -e "$XZDRPATH/drdebug" ]; then

	# Turn on a blue led, as a visual warning to the user
	setled on 0 0 255

	writelog "Found debugging script, copying it in place of /sbin/init!"
	execlog mount -o remount,rw rootfs /
	cp $XZDRPATH/drdebug /sbin/init
	execlog mount -o remount,ro rootfs /
	export XZDRLOGFILE="$XZDRPATH/XZDebug.log"

	sleep 2

	setled off

fi

# One last failsafe...
if [ -e "/sbin/init" ]; then

	exec /sbin/init.sh

else

	exit2bin

fi
