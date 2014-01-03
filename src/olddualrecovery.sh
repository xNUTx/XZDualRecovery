#!/sbin/busybox sh
#
# Dual Recovery for Z
#
# Author:
#   [NUT]
# Thanks go to DooMLoRD for the keycodes and a working example!
#
###########################################################################

set +x
_PATH="$PATH"
export PATH="/system/xbin"

# Defining constants, from commandline
DRPATH="$1"
LOGFILE="$2"
LOG="${DRPATH}/${LOGFILE}"

# Kickstarting log
DATETIME=`date +"%d-%m-%Y %H:%M:%S"`
echo "START Dual Recovery at ${DATETIME}: STAGE 2." > ${LOG}

# Z setup
#BOOTREC_CACHE_NODE="/dev/block/mmcblk0p25 b 179 25"
#BOOTREC_CACHE="/dev/block/mmcblk0p25"
BOOTREC_EXTERNAL_SDCARD_NODE="/dev/block/mmcblk1p1 b 179 32"
BOOTREC_EXTERNAL_SDCARD="/dev/block/mmcblk1p1"
BOOTREC_LED_RED="/sys/class/leds/lm3533-red/brightness"
BOOTREC_LED_GREEN="/sys/class/leds/lm3533-green/brightness"
BOOTREC_LED_BLUE="/sys/class/leds/lm3533-blue/brightness"

# Defining functions
ECHOL(){
  _TIME=`date +"%H:%M:%S"`
  echo "${_TIME}: $*" >> ${LOG}
  return 0
}
EXECL(){
  _TIME=`date +"%H:%M:%S"`
  echo "${_TIME}: $*" >> ${LOG}
  $* 2>&1 >> ${LOG}
  _RET=$?
  echo "${_TIME}: RET=${_RET}" >> ${LOG}
  return ${_RET}
}

ECHOL "Checking device model..."
MODEL=`/system/bin/getprop ro.product.model`
VERSION=`/system/bin/getprop ro.build.id`
PHNAME=`/system/bin/getprop ro.semc.product.name`

ECHOL "Model found: ${MODEL} (${PHNAME} - ${VERSION})"

ECHOL "Setting up Keychecking..."
SKIP=5
INPUTS=10
ECHOL "Working with $INPUTS event nodes, skipping $SKIP!"
INPUTID=0
INPUTNID=64

LessTest() {
	if [ "$INPUTID" = "$INPUTS" ]; then
		return 0
	else
		return 1
	fi
}

until LessTest
do

	if [ $INPUTID -lt $SKIP ]; then
		INPUTID=`expr $INPUTID + 1`
		INPUTNID=`expr $INPUTNID + 1`
		continue
	fi

	BOOTREC_EVENT="/dev/input/event$INPUTID"
	BOOTREC_EVENT_NODE="${BOOTREC_EVENT} c 13 $INPUTNID"

	if [ ! -c ${BOOTREC_EVENT} ]; then
		EXECL mknod -m 660 ${BOOTREC_EVENT_NODE}
	fi

	ECHOL "Listening on $BOOTREC_EVENT"
	cat ${BOOTREC_EVENT} > /dev/keycheck$INPUTID &

	INPUTID=`expr $INPUTID + 1`
	INPUTNID=`expr $INPUTNID + 1`

done

ECHOL "DR Keycheck..."

# Vibrate to alert user to make a choice
ECHOL "Trigger vibrator"
echo 200 > /sys/class/timed_output/vibrator/enable

# Turn on green LED as a visual cue
ECHOL "Turn on green led"
echo 0 > ${BOOTREC_LED_RED}
echo 255 > ${BOOTREC_LED_GREEN}
echo 0 > ${BOOTREC_LED_BLUE}

EXECL sleep 3

KEYCHECK=""
INPUTID=0

for INPUT in `find /dev/input/event* | sort -k1.17n`; do

	if [ $INPUTID -lt $SKIP ]; then
		INPUTID=`expr $INPUTID + 1`
		continue
	fi

	hexdump < /dev/keycheck$INPUTID > /dev/keycheckout$INPUTID

	VOLUKEYCHECK=`cat /dev/keycheckout$INPUTID | grep '0001 0073' | wc -l`
	VOLDKEYCHECK=`cat /dev/keycheckout$INPUTID | grep '0001 0072' | wc -l`

	if [ "$VOLUKEYCHECK" != "0" ]; then
		ECHOL "Recorded VOL-UP on $INPUT!"
		KEYCHECK="UP"
	elif [ "$VOLDKEYCHECK" != "0" ]; then
		ECHOL "Recorded VOL-DOWN on $INPUT!"
		KEYCHECK="DOWN"
	fi

	EXECL rm -f /dev/keycheck$INPUTID
	EXECL rm -f /dev/keycheckout$INPUTID

	INPUTID=`expr $INPUTID + 1`

done

EXECL killall cat

if [ "$KEYCHECK" != "" -o -e "${DRPATH}/boot" -o -e "/cache/recovery/boot" ]; then

	ECHOL "Recovery boot mode selected"

	# Recovery boot mode notification
	ECHOL "Turn led purple"
	echo 255 > ${BOOTREC_LED_RED}
	echo 0 > ${BOOTREC_LED_GREEN}
	echo 255 > ${BOOTREC_LED_BLUE}

	if [ -e ${DRPATH}/boot ]; then
		EXECL rm ${DRPATH}/boot
	fi

	if [ -e /cache/recovery/boot ]; then
		EXECL rm /cache/recovery/boot
	fi

	cd /

	#read what CWM to use
	if [ -f "${DRPATH}/cwm" ]; then
		ECHOL "User defined choice for vanilla CWM!"
		CWM="cwm"
	else
		ECHOL "Will be using PhilZ Touch Recovery when CWM choice has been made!"
		CWM="philz"
	fi

	#read default, for use with the boot flag file.
	if [ -e ${DRPATH}/default -a "`cat ${DRPATH}/default`" = "twrp" ]; then
		RECLOG="Booting TWRP by default..."
		RECOVERY="/sbin/recovery.twrp.cpio.lzma"
	else
		RECLOG="Booting CWM by default..."
		RECOVERY="/sbin/recovery.${CWM}.cpio.lzma"
	fi

  	# Prepare CWM recovery
	if [ -f /system/bin/recovery.cwm.cpio.lzma -a "$KEYCHECK" = "UP" ]; then
		RECLOG="Booting CWM by keypress..."
		RECOVERY="/sbin/recovery.${CWM}.cpio.lzma"
	fi

	# Prepare TWRP recovery
	if [ -f /system/bin/recovery.twrp.cpio.lzma -a "$KEYCHECK" = "DOWN" ]; then
		RECLOG="Booting TWRP by keypress..."
		RECOVERY="/sbin/recovery.twrp.cpio.lzma"
	fi

	# Boot the recovery, if the file exists
	if [ -f "${RECOVERY}" ]; then

		# Record choice in log
		ECHOL "${RECLOG}"

		# Setting cpu frequencies, to speed up things up
#		ECHOL "Setting CPU max frequency to 1.5Ghz..."
#		echo 1512000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
#		echo 1512000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
#		echo 1512000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
#		echo 1512000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
#		ECHOL "Setting CPU min frequency to 1Ghz..."
#		echo 1008000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
#		echo 1008000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
#		echo 1008000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
#		echo 1008000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq

		# Initialize system clock.
		if [ "$(getprop persist.sys.timezone)" = "Europe/Amsterdam" ]; then
		  ECHOL "Europe/Amsterdam timezone..."
		  EXECL export TZ=GMT+1
		fi
		ECHOL "Start time_daemon..."
		/system/bin/time_daemon &
		EXECL sleep 2
		ECHOL "Kill time_daemon..."
		EXECL kill -9 $(ps | grep time_daemon | grep -v "grep" | awk -F' ' '{print $1}')

		# Stop init services.
		ECHOL "Stop init services..."
		for SVCRUNNING in $(getprop | grep -E '^\[init\.svc\..*\]: \[running\]')
		do
		  SVCNAME=$(expr ${SVCRUNNING} : '\[init\.svc\.\(.*\)\]:.*')
		  EXECL stop ${SVCNAME}
		done

		EXECL kill -9 $(ps | grep rmt_storage | grep -v "grep" | awk -F' ' '{print $1}')

		# umount partitions, stripping the ramdisk to bare metal
		ECHOL "Umount partitions and then executing init..."
		EXECL umount -l /acct
		EXECL umount -l /dev/cpuctl
		EXECL umount -l /dev/pts
		EXECL umount -l /mnt/asec
		EXECL umount -l /mnt/obb
		EXECL umount -l /mnt/qcks
		EXECL umount -l /data/idd	# Appslog
		EXECL umount -l /data		# Userdata
		EXECL umount -l /lta-label	# LTALabel

		# AS OF HERE NO MORE BUSYBOX SYMLINKS IN $PATH!!!!

		busybox umount -l /system	# System
		export PATH="/sbin"

		# rm symlinks & files.
		busybox find . -maxdepth 1 \( -type l -o -type f \) -exec busybox rm -fv {} \; 2>&1 >> ${LOG}

		for directory in `busybox find . -maxdepth 1 -type d`; do
			if [ "$directory" != "." -a "$directory" != ".." -a "$directory" != "./" -a "$directory" != "./dev" -a "$directory" != "./proc" -a "$directory" != "./sys" -a "$directory" != "./sbin" -a "$directory" != "./cache" -a "$directory" != "./storage" ]; then
				busybox echo "rm -vrf $directory" >> ${LOG}
				busybox rm -vrf $directory 2>&1 >> ${LOG}
			fi
		done

		# extract recovery
		busybox echo "Extracting recovery..." >> ${LOG}
		busybox lzcat ${RECOVERY} | busybox cpio -i -u

		# Turn off LED
		echo "turn off the LED..." >> ${LOG}
		echo 0 > ${BOOTREC_LED_RED}
		echo 0 > ${BOOTREC_LED_GREEN}
		echo 0 > ${BOOTREC_LED_BLUE}

		# From here on, the log dies, as these are the locations we log to!
		# Ending log
		DATETIME=`busybox date +"%d-%m-%Y %H:%M:%S"`
		echo "STOP Dual Recovery at ${DATETIME}: Executing recovery init, have fun!" >> ${LOG}
		umount -l /storage/sdcard1	# SDCard1
		umount -l /cache		# Cache
		umount -l /proc
		umount -l /sys

		# exec
		exec /init

	else

		ECHOL "The recovery file does not exist, exitting with a visual warning!"
		echo 255 > ${BOOTREC_LED_RED}
		echo 0 > ${BOOTREC_LED_GREEN}
		echo 0 > ${BOOTREC_LED_BLUE}

		sleep 2

	fi

fi

# Turn off LED
ECHOL "Turning off led..."
echo 0 > ${BOOTREC_LED_RED}
echo 0 > ${BOOTREC_LED_GREEN}
echo 0 > ${BOOTREC_LED_BLUE}

ECHOL "Remount / ro..."
mount -o remount,ro rootfs /
ECHOL "Remount /system ro..."
mount -o remount,ro /system

ECHOL "Return to normal boot mode..."

# Ending log
DATETIME=`busybox date +"%d-%m-%Y %H:%M:%S"`
echo "STOP Dual Recovery at ${DATETIME}: STAGE 2." >> ${LOG}

# Unmount SDCard1
umount -l /storage/sdcard1

# Return path variable to default
export PATH="${_PATH}"

# Continue booting
exec /system/bin/chargemon.stock
