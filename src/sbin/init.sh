#!/sbin/busybox sh
#
# Multi Recovery for many Sony Xperia devices!
#
# Author:
#   [NUT], AngelBob, Olivier and shoey63
#
# - Thanks go to DooMLoRD for the keycodes and a working example!
# - My gratitude also goes out to Androxyde for his sometimes briliant
#   ideas to simplify things while writing the scripts!
#
###########################################################################

set +x
PATH="/system/.xzdr/bin:/system/.xzdr/sbin:/sbin"

writelog "Checking device model..."
MODEL=$(drgetprop ro.product.model)
VERSION=$(drgetprop ro.build.id)
PHNAME=$(drgetprop ro.semc.product.name)
EVENTNODE=$(drgetprop dr.gpiokeys.node)

writelog "Model found: $MODEL ($PHNAME - $VERSION)"

execlog mount -o remount,rw rootfs /

RECOVERYBOOT="false"
KEYCHECK=""

if [ "$(grep 'warmboot=0x77665502' /proc/cmdline | wc -l)" = "1" ]; then

	writelog "Reboot 'recovery' trigger found."
	RECOVERYBOOT="true"

elif [ -f "/cache/recovery/boot" -o -f "${DRPATH}/boot" ]; then

	writelog "Recovery 'boot file' trigger found."
	RECOVERYBOOT="true"

else

	writelog "DR Keycheck..."
	cat ${EVENTNODE} > /dev/keycheck &

	# Vibrate to alert user to make a choice
	writelog "Trigger vibrator"
	echo 150 > /sys/class/timed_output/vibrator/enable
	usleep 300000
	echo 150 > /sys/class/timed_output/vibrator/enable

	# Turn on green LED as a visual cue
	SETLED on 0 255 0

	execlog sleep 3

	hexdump < /dev/keycheck > /dev/keycheckout

	VOLUKEYCHECK=`cat /dev/keycheckout | grep '0001 0073' | wc -l`
	VOLDKEYCHECK=`cat /dev/keycheckout | grep '0001 0072' | wc -l`

	if [ "$VOLUKEYCHECK" != "0" ]; then
		writelog "Recorded VOL-UP on ${EVENTNODE}!"
		KEYCHECK="UP"
	elif [ "$VOLDKEYCHECK" != "0" ]; then
		writelog "Recorded VOL-DOWN on ${EVENTNODE}!"
		KEYCHECK="DOWN"
	elif [ "$VOLUKEYCHECK" != "0" -a "$VOLDKEYCHECK" != "0" ]; then
		writelog "Recorded BOTH VOL-UP & VOL-DOWN on ${EVENTNODE}! Making the choice to go to the UP target..."
		KEYCHECK="UP"
	fi

	execlog killall cat

	execlog rm -f /dev/keycheck
	execlog rm -f /dev/keycheckout

	execlog mount -o remount,ro rootfs /

	if [ "$KEYCHECK" != "" ]; then

		writelog "Recovery 'volume button' trigger found."
		RECOVERYBOOT="true"

	fi

fi

if [ "$RECOVERYBOOT" = "true" ]; then

	# Recovery boot mode notification
	SETLED on 255 0 255

	if [ -f "/cache/recovery/boot" ]; then
		execlog rm -f /cache/recovery/boot
	fi

	cd /

	execlog mount -o remount,rw rootfs /

	# reboot recovery trigger or boot file found, no keys pressed: read what recovery to use
	if [ "$KEYCHECK" = "" ]; then
		RECLOAD="$(drgetprop dr.recovery.boot)"
		RECLOG="Booting to ${RECLOAD}..."
	fi

  	# Prepare PhilZ recovery - by button press
	if [ -f "/system/.xzdr/lib/recovery.philz.cpio.lzma" -a "$KEYCHECK" = "UP" ]; then
		RECLOAD="philz"
		RECLOG="Booting recovery by keypress, booting to PhilZ Touch..."
	fi

	# Prepare TWRP recovery - by button press
	if [ -f "/system/.xzdr/lib/recovery.twrp.cpio.lzma" -a "$KEYCHECK" = "DOWN" ]; then
		RECLOAD="twrp"
		RECLOG="Booting recovery by keypress, booting to TWRP..."
	fi

	# Copy, unpack and prepare loading the recovery.
	drsetprop dr.recovery.boot ${RECLOAD}
	execlog cp /system/.xzdr/lib/recovery.${RECLOAD}.cpio.lzma /sbin/
	execlog lzma -d /sbin/recovery.${RECLOAD}.cpio.lzma
	RECOVERY="/sbin/recovery.${RECLOAD}.cpio"

	# Boot the recovery, if the file exists
	if [ -f "${RECOVERY}" ]; then

		# Record choice in log
		writelog "${RECLOG}"

		# Stop init services.
		writelog "Stop init services..."
		for SVCRUNNING in $(getprop | grep -E '^\[init\.svc\..*\]: \[running\]'); do
			SVCNAME=$(expr ${SVCRUNNING} : '\[init\.svc\.\(.*\)\]:.*')
			if [ "${SVCNAME}" != "" ]; then
				execlog stop ${SVCNAME}
				if [ -f "/system/bin/${SVCNAME}" ]; then
					execlog pkill -f /system/bin/${SVCNAME}
				fi
			fi
		done

		# Preemptive strike against locking applications
		for LOCKINGPID in `lsof | awk '{print $1" "$2}' | grep "/bin\|/system\|/data\|/cache" | awk '{print $1}'`; do
			BINARY=$(cat /proc/${LOCKINGPID}/status | grep -i "name" | awk -F':\t' '{print $2}')
			if [ "$BINARY" != "" ]; then
				writelog "File ${BINARY} is locking a critical partition running as PID ${LOCKINGPID}, killing it now!"
				execlog killall $BINARY
			fi
		done

		# umount partitions, stripping the ramdisk to bare metal
		writelog "Umount partitions and then executing init..."
		execlog umount -l /acct
		execlog umount -l /dev/cpuctl
		execlog umount -l /dev/pts
		execlog umount -l /mnt/int_storage
		execlog umount -l /mnt/asec
		execlog umount -l /mnt/obb
		execlog umount -l /mnt/qcks
		execlog umount -l /mnt/idd	# Appslog
		execlog umount -l /data/idd	# Appslog
		execlog umount -l /data		# Userdata
		execlog umount -l /lta-label	# LTALabel

		# Create recovery directory to create a new root in.
		execlog mkdir /recovery
		execlog cd /recovery

		# extract recovery
		writelog "Extracting recovery..."
		execlog cpio -i -u < /sbin/recovery.${RECLOAD}.cpio

		execlog pwd
		execlog ls -la

		# Turn off LED
		SETLED off

		# From here on, the log dies, as these are the locations we log to!
		# Ending log
		DATETIME=`date +"%d-%m-%Y %H:%M:%S"`
		writelog "STOP Dual Recovery at ${DATETIME}: Executing recovery init, have fun!"

		umount -l /storage/sdcard1	# SDCard1
		umount -l /cache		# Cache
#		umount -l /proc
#		umount -l /sys

		# AS OF HERE NO MORE BUSYBOX SYMLINKS IN $PATH!!!!

		export PATH="/sbin"
		busybox umount -l /system	# System

		# exec
		busybox chroot /recovery /init

	else

		execlog mount -o remount,ro rootfs /

		writelog "The recovery file does not exist, exitting with a visual warning!"
		SETLED on 255 0 0

		sleep 2

	fi

fi

# Turn off LED
SETLED off

# Check and prepare for stock ramdisk
STOCKRAMDISK=""
PACKED=""
INSECUREBOOT=""
if [ -f "$(drgetprop dr.ramdisk.path)" ] && [ "$(drgetprop dr.ramdisk.boot)" = "true" -o -f "/cache/ramdisk" ]; then

	if [ -f "/cache/ramdisk" ]; then
		execlog rm -f /cache/ramdisk
	fi

	STOCKRAMDISK=$(drgetprop dr.ramdisk.path)
	PACKED=$(basename $STOCKRAMDISK | awk -F . '{print $NF}')
	INSECUREBOOT="true"

fi

if [ -f "$(drgetprop dr.ramdisk.path)" -a "$(drgetprop dr.ramdisk.boot)" = "power" ]; then

	POWERNODE=$(drgetprop dr.pwrkey.node)
	writelog "Power keycheck..."
	execlog mount -o remount,rw rootfs /

	cat ${POWERNODE} > /dev/keycheck &

	# Vibrate to alert user to make a choice
	writelog "Trigger vibrator"
	echo 150 > /sys/class/timed_output/vibrator/enable
	usleep 300000
	echo 150 > /sys/class/timed_output/vibrator/enable

	# Turn on amber LED as a visual cue
	SETLED on 255 255 0

	execlog sleep 3

	KEYCHECK=""

	hexdump < /dev/keycheck > /dev/keycheckout

	SETLED off

	POWERKEYCHECK=`cat /dev/keycheckout | wc -l`

	if [ "$POWERKEYCHECK" != "0" ]; then
		writelog "Power button pressed, will attempt booting insecure ramdisk!"
		STOCKRAMDISK=$(drgetprop dr.ramdisk.path)
		PACKED=$(basename $STOCKRAMDISK | awk -F . '{print $NF}')
		INSECUREBOOT="true"
	fi

	execlog killall cat

	execlog rm -f /dev/keycheck
	execlog rm -f /dev/keycheckout

	execlog mount -o remount,ro rootfs /

fi

if [ "$PACKED" != "" -a "$PACKED" != "lzma" -a "$PACKED" != "cpio" -a "$PACKED" != "tar" ]; then

	writelog "Unknown archive type, use only cpio, cpio.lzma and tar archives!"
	STOCKRAMDISK=""

fi

# If the ramdisk is not present or if the setting in the XZDR.prop
# file has been set to disabled, we do a regular boot.
if [ "$STOCKRAMDISK" != "" -a "$INSECUREBOOT" != "" ]; then

	execlog mount -o remount,rw rootfs /

	writelog "Known archive type, will copy it to /sbin now"
	execlog cp $STOCKRAMDISK /sbin/
	STOCKRAMDISK="/sbin/$(basename $STOCKRAMDISK)"

	writelog "Insecure ramdisk boot..."

	cd /

	# extract replacement ramdisk
	writelog "Extracting ramdisk..."
	if [ "$PACKED" = "tar" ]; then
		tar xf $STOCKRAMDISK
	elif [ "$PACKED" = "cpio" ]; then
		cpio -i -u < $STOCKRAMDISK
	else
		lzcat $STOCKRAMDISK | cpio -i -u
	fi

	# Ending log
	DATETIME=`date +"%d-%m-%Y %H:%M:%S"`
	writelog "STOP Dual Recovery at ${DATETIME}: Executing insecure ramdisk init, have fun!"

	# exec
	exec /init

else

	# init.d support
	if [ "$(drgetprop dr.initd.active)" = "true" ]; then

		writelog "Init.d folder found and execution is enabled!"
		writelog "It will run the following scripts:"
		run-parts -t /system/etc/init.d 2>&1 >> ${LOG}
		writelog "Executing them in the background now."
		nohup run-parts /system/etc/init.d &

	else

		writelog "Init.d execution is disabled."
		writelog "To enable it, set dr.initd.active to true in XZDR.prop!"

	fi

	writelog "Starting the rickiller to the background..."
	nohup /system/.xzdr/sbin/rickiller.sh &

	execlog mount -o remount,ro rootfs /
	execlog mount -o remount,ro /system

	writelog "Return to normal boot mode..."
	
	/system/bin/setprop dr.xzdr.installed true

	# Ending log
	DATETIME=`busybox date +"%d-%m-%Y %H:%M:%S"`
	echo "STOP Dual Recovery at ${DATETIME}: STAGE 2." >> $XZDRLOGFILE

	# Unmount SDCard1
	umount -f /storage/sdcard1

	# Continue booting
	exec /system/bin/$1.stock

fi
