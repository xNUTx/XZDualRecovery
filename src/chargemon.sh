#!/system/bin/sh
#
# Dual Recovery for many Sony Xperia devices!
#
# Author:
#   [NUT]
#
# - Thanks go to DooMLoRD for the keycodes and a working example!
# - My gratitude also goes out to Androxyde for his sometimes briliant
#   ideas to simplify things while writing the scripts!
#
###########################################################################

set +x
_PATH="$PATH"
export PATH="/system/xbin:/system/bin:/sbin"

# Constants
LOGDIR="XZDualRecovery"
SECUREDIR="/system/.XZDualRecovery"
PREPLOG="/tmp/${LOGDIR}/preperation.log"
LOGFILE="XZDualRecovery.log"

# Nodes setup
BOOTREC_EXTERNAL_SDCARD_NODE="/dev/block/mmcblk1p1 b 179 32"
BOOTREC_EXTERNAL_SDCARD="/dev/block/mmcblk1p1"

REDLED=$(/system/xbin/busybox ls -1 /sys/class/leds|/system/xbin/busybox grep "red\|LED1_R")
GREENLED=$(/system/xbin/busybox ls -1 /sys/class/leds|/system/xbin/busybox grep "green\|LED1_G")
BLUELED=$(/system/xbin/busybox ls -1 /sys/class/leds|/system/xbin/busybox grep "blue\|LED1_B")

# Function definitions
TECHOL(){
  _TIME=`/system/xbin/busybox date +"%H:%M:%S"`
  echo "${_TIME} >> $*" >> ${PREPLOG}
  return 0
}
TEXECL(){
  _TIME=`/system/xbin/busybox date +"%H:%M:%S"`
  echo "${_TIME} >> $*" >> ${PREPLOG}
  $* >> ${PREPLOG} 2>> ${PREPLOG}
  _RET=$?
  echo "${_TIME} >> RET=${_RET}" >> ${PREPLOG}
  return ${_RET}
}
BEXECL(){
  _TIME=`/system/xbin/busybox date +"%H:%M:%S"`
  echo "${_TIME} >> $*" >> ${PREPLOG}
  busybox $* >> ${PREPLOG} 2>> ${PREPLOG}
  _RET=$?
  echo "${_TIME} >> RET=${_RET}" >> ${PREPLOG}
  return ${_RET}
}
#86|87) TEXECL mount -t ntfs ${BOOTREC_EXTERNAL_SDCARD} /storage/sdcard1; return $?;;
MOUNTSDCARD(){
	TEXECL blockdev --setrw ${BOOTREC_EXTERNAL_SDCARD};
	case $* in
		06|6|0B|b|0C|c|0E|e) TEXECL mount -t vfat ${BOOTREC_EXTERNAL_SDCARD} /storage/sdcard1; return $?;;
		07|7) TEXECL insmod /system/lib/modules/nls_utf8.ko;
		      TEXECL insmod /system/lib/modules/texfat.ko;
		      TEXECL mount -t texfat ${BOOTREC_EXTERNAL_SDCARD} /storage/sdcard1;
		      return $?;;
		83) PTYPE=$(/system/xbin/busybox blkid ${BOOTREC_EXTERNAL_SDCARD} | /system/xbin/busybox awk -F' ' '{ print $NF }' | /system/xbin/busybox awk -F'[\"=]' '{ print $3 }');
		    TEXECL mount -t $PTYPE ${BOOTREC_EXTERNAL_SDCARD} /storage/sdcard1;
		    return $?;;
		 *) return 1;;
	esac
	TECHOL "### MOUNTSDCARD did not run with a parameter!";
	return 1;
}
SETLED() {
        BRIGHTNESS_LED_RED="/sys/class/leds/$REDLED/brightness"
        CURRENT_LED_RED="/sys/class/leds/$REDLED/led_current"
        BRIGHTNESS_LED_GREEN="/sys/class/leds/$GREENLED/brightness"
        CURRENT_LED_GREEN="/sys/class/leds/$GREENLED/led_current"
        BRIGHTNESS_LED_BLUE="/sys/class/leds/$BLUELED/brightness"
        CURRENT_LED_BLUE="/sys/class/leds/$BLUELED/led_current"

        if [ "$1" = "on" ]; then

                TECHOL "Turn on LED R: $2 G: $3 B: $4"
                echo "$2" > ${BRIGHTNESS_LED_RED}
                echo "$3" > ${BRIGHTNESS_LED_GREEN}
                echo "$4" > ${BRIGHTNESS_LED_BLUE}

                if [ -f "$CURRENT_LED_RED" -a -f "$CURRENT_LED_GREEN" -a -f "$CURRENT_LED_BLUE" ]; then

                        echo "$2" > ${CURRENT_LED_RED}
                        echo "$3" > ${CURRENT_LED_GREEN}
                        echo "$4" > ${CURRENT_LED_BLUE}
                fi

        else

                TECHOL "Turn off LED"
                echo "0" > ${BRIGHTNESS_LED_RED}
                echo "0" > ${BRIGHTNESS_LED_GREEN}
                echo "0" > ${BRIGHTNESS_LED_BLUE}

                if [ -f "$CURRENT_LED_RED" -a -f "$CURRENT_LED_GREEN" -a -f "$CURRENT_LED_BLUE" ]; then

                        echo "0" > ${CURRENT_LED_RED}
                        echo "0" > ${CURRENT_LED_GREEN}
                        echo "0" > ${CURRENT_LED_BLUE}
                fi

        fi
}
EXIT2CM(){
	# Turn on a red led, as a visual warning to the user
	SETLED on 255 0 0

	/system/xbin/busybox sleep 2

	# Turn off LED
	SETLED off

	# Ending log
	DATETIME=`/system/xbin/busybox date +"%d-%m-%Y %H:%M:%S"`
	echo "STOP Dual Recovery STAGE 1 at ${DATETIME}" >> ${PREPLOG}

	/system/xbin/busybox umount -l /storage/sdcard1

	/system/xbin/busybox rmmod -f byeselinux.ko

	export PATH="${_PATH}"

	exec /system/bin/chargemon.stock
	exit 0
}
DRGETPROP() {

	# If it's empty, see if what was requested was a XZDR.prop value!
	VAR="$*"
	PROP=$(${BUSYBOX} grep "$VAR" ${DRPATH}/XZDR.prop | ${BUSYBOX} awk -F'=' '{ print $NF }')

	if [ "$PROP" = "" ]; then

		# If it still is empty, try to get it from the build.prop
		PROP=$(${BUSYBOX} grep "$VAR" /system/build.prop | ${BUSYBOX} awk -F'=' '{ print $NF }')

	fi

	if [ "$VAR" != "" -a "$PROP" != "" ]; then
		echo $PROP
	else
		echo "null"
	fi

}
DRSETPROP() {

	# We want to set this only if the XZDR.prop file exists...
	if [ ! -f "${DRPATH}/XZDR.prop" ]; then
		echo "" > ${DRPATH}/XZDR.prop
	fi

	PROP=$(DRGETPROP $1)

	if [ "$PROP" != "null" ]; then
		${BUSYBOX} sed -i 's|'$1'=[^ ]*|'$1'='$2'|' ${DRPATH}/XZDR.prop
	else
		${BUSYBOX} echo "$1=$2" >> ${DRPATH}/XZDR.prop
	fi
	return 0

}

# Find the gpio-keys node, to listen on the right input event
gpioKeysSearch() {
	TECHOL "Trying to find the gpio-keys event node."
	for INPUTUEVENT in `${BUSYBOX} find /sys/devices \( -path "*gpio*" -path "*keys*" -a -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

		INPUTDEV=$(${BUSYBOX} grep "DEVNAME=" ${INPUTUEVENT} | ${BUSYBOX} sed 's/DEVNAME=//')

		if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
			TECHOL "Found and will be using /dev/${INPUTDEV}!"
			echo "/dev/${INPUTDEV}"
			return 0
		fi

	done
	return 1
}

# Find the power key node, to listen on the right input event
pwrkeySearch() {
	TECHOL "Trying to find the power key event node."
	# pm8xxx (xperia Z and similar)
	for INPUTUEVENT in `${BUSYBOX} find /sys/devices \( -path "*pm8xxx*" -path "*pwrkey*" -a -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

		INPUTDEV=$(${BUSYBOX} grep "DEVNAME=" ${INPUTUEVENT} | ${BUSYBOX} sed 's/DEVNAME=//')

		if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
			TECHOL "Found and will be monitoring /dev/${INPUTDEV}!"
			echo "/dev/${INPUTDEV}"
			return 0
		fi

	done
	# qpnp_pon (xperia Z1 and similar)
	for INPUTUEVENT in `find $(find /sys/devices/ -name "name" -exec grep -l "qpnp_pon" {} \; | awk -F '/' 'sub(FS $NF,x)') \( -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

		INPUTDEV=$(${BUSYBOX} grep "DEVNAME=" ${INPUTUEVENT} | ${BUSYBOX} sed 's/DEVNAME=//')

		if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
			TECHOL "Found and will be monitoring /dev/${INPUTDEV}!"
			echo "/dev/${INPUTDEV}"
			return 0
		fi

	done
	return 1
}

# We can safely asume a busybox exists in /system/xbin (as XZDualRecovery installs one there)
${BUSYBOX} mount -o remount,rw rootfs /
MADETMP="false"
if [ ! -d "/tmp" ]; then

	mkdir /tmp
	${BUSYBOX} mount -t tmpfs tmpfs /tmp
	echo "Created /tmp!" >> ${PREPLOG}

fi
${BUSYBOX} mkdir /tmp/XZDualRecovery
${BUSYBOX} mount -o remount,ro rootfs /

# Kickstarting log
DATETIME=`${BUSYBOX} date +"%d-%m-%Y %H:%M:%S"`
echo "START Dual Recovery at ${DATETIME}: STAGE 1." > ${PREPLOG}

NOGOODBUSYBOX="true"
# Busybox setup, chosing the one that supports lzma, as it is vital for this recovery setup!
if [ -x "/system/xbin/busybox" -a ! -n "${BUSYBOX}" ]; then
	CHECK=`/system/xbin/busybox --list | /system/xbin/busybox grep lzma | /system/xbin/busybox wc -l`
	if [ "$CHECK" -gt "0" ]; then
 		BUSYBOX="/system/xbin/busybox"
		NOGOODBUSYBOX="false"
	fi
fi
# Fallback to the one in /system/bin, but only if it supports lzma...
if [ -x "/system/bin/busybox" -a "$NOGOODBUSYBOX" = "true" ]; then
	CHECK=`/system/bin/busybox --list | /system/bin/busybox grep lzma | /system/bin/busybox wc -l`
	if [ "$CHECK" -gt "0" ]; then
		BUSYBOX="/system/bin/busybox"
		NOGOODBUSYBOX="false"
	fi
fi

#https://github.com/android/platform_system_core/commit/e18c0d508a6d8b4376c6f0b8c22600e5aca37f69
#The busybox in all of the recoveries has not yet been patched to take this in account.
${BUSYBOX} blockdev --setrw $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system")
${BUSYBOX} blockdev --setrw $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "cache")

# Part of byeselinux, requisit for Lollipop based firmwares.
echo "Checking if byeselinux is required..." >> ${PREPLOG}
ANDROIDVER=`${BUSYBOX} echo "$(DRGETPROP ro.build.version.release) 5.0.0" | ${BUSYBOX} awk '{if ($2 != "" && $1 >= $2) print "lollipop"; else print "other"}'`
echo "ro.build.version.release=$(DRGETPROP ro.build.version.release), test result: $ANDROIDVER" >> ${PREPLOG}
if [ "$ANDROIDVER" = "lollipop" ]; then
	echo "Byeselinux is required." >> ${PREPLOG}
        # This will allow the modification of the ramdisk, but will only be loaded if needed.
	if [ -e "/system/lib/modules/byeselinux.ko" ]; then
		echo "Module found, loading it now..." >> ${PREPLOG}
		${BUSYBOX} insmod /system/lib/modules/byeselinux.ko
		if [ "$?" != "0" -a "$?" != "17" ]; then
			echo "Loading the module failed with exit code $?" >> ${PREPLOG}
		fi
	else
		echo "Byeselinux module not found!" >> ${PREPLOG}
	fi
fi

# If no good busybox has been found, we will replace the one in xbin
# This was never so important but with the release of the JB4.3 ROM on the Z1, Z1 Compact and Z Ultra
# this missing busybox will break full root provided by XZDualRecovery making these
# user errors that more painful.
if [ "$NOGOODBUSYBOX" = "true" -a -d "$SECUREDIR" ]; then

	$SECUREDIR/busybox mount -o remount,rw /system
	$SECUREDIR/busybox cp $SECUREDIR/busybox /system/xbin/
	chmod 755 /system/xbin/busybox
	BUSYBOX="/system/xbin/busybox"
	rm /system/etc/.xzdrbusybox
	${BUSYBOX} mount -o remount,ro /system
	echo "Replaced busybox in /system/xbin!" >> ${PREPLOG}

fi

if [ -d "$SECUREDIR" ]; then

	${BUSYBOX} mount -o remount,rw /system
	${BUSYBOX} cp /init.* $SECUREDIR/
	${BUSYBOX} mount -o remount,ro /system
	echo "Made a copy of all the init RC files in to $SECUREDIR!" >> ${PREPLOG}

fi

if [ ! -d "$SECUREDIR" -o ! -x "$SECUREDIR/busybox" ] && [ -x "${BUSYBOX}" ]; then

	${BUSYBOX} mount -o remount,rw /system
	if [ ! -d "$SECUREDIR" ]; then
		${BUSYBOX} mkdir $SECUREDIR
	fi
	if [ ! -x "$SECUREDIR/busybox" ]; then
		${BUSYBOX} cp ${BUSYBOX} $SECUREDIR/
		${BUSYBOX} chmod 755 $SECUREDIR/busybox
	fi
	echo "Created $SECUREDIR and put a busybox safety copy away in it.!" >> ${PREPLOG}
	${BUSYBOX} mount -o remount,ro /system

fi

if [ -x "${BUSYBOX}" ]; then

	TECHOL "Using ${BUSYBOX}"

	TEXECL ${BUSYBOX} mount -o remount,rw rootfs /
	TEXECL ${BUSYBOX} mount -o remount,rw /system

	if [ "$(${BUSYBOX} grep '/sys/kernel/security/sony_ric/enable' /init.* | ${BUSYBOX} wc -l)" != "0" ]; then
		TECHOL "Sony's kernel security trigger found, running disableric."
		TEXECL ${BUSYBOX} mount -t securityfs -o nosuid,nodev,noexec securityfs /sys/kernel/security
		TEXECL ${BUSYBOX} mkdir -p /sys/kernel/security/sony_ric
		TEXECL ${BUSYBOX} chmod 755 /sys/kernel/security/sony_ric
		TEXECL ${BUSYBOX} echo "0" > /sys/kernel/security/sony_ric/enable
	fi

	if [ -e "/sbin/ric" ]; then
		RICPATH="/sbin/ric"
		TEXECL ${BUSYBOX} rm $RICPATH
		TEXECL ${BUSYBOX} touch $RICPATH
		${BUSYBOX} echo "#!/system/bin/sh" >> $RICPATH
		${BUSYBOX} echo "while :" >> $RICPATH
		${BUSYBOX} echo "do" >> $RICPATH
		${BUSYBOX} echo 'if [ "$(busybox blockdev --getro $(find /dev/block/platform/msm_sdcc.1/by-name/ -iname system))" = "1" ]; then' >> $RICPATH
		${BUSYBOX} echo "busybox blockdev --setrw $(find /dev/block/platform/msm_sdcc.1/by-name/ -iname system)" >> $RICPATH
		${BUSYBOX} echo "fi" >> $RICPATH
		${BUSYBOX} echo "sleep 60" >> $RICPATH
		${BUSYBOX} echo "done" >> $RICPATH
		TEXECL ${BUSYBOX} chmod 755 $RICPATH
		TEXECL ${BUSYBOX} touch /tmp/killedric
	fi

	if [ -e "/system/lib/modules/wp_mod.ko" ]; then
		TECHOL "MohammadAG's module is available, lets load it."
		TEXECL ${BUSYBOX} insmod /system/lib/modules/wp_mod.ko
	fi

	if [ -x "${BUSYBOX}" -a -x "/system/bin/dualrecovery.sh" ]; then

		TECHOL "Install busybox to /sbin..."
		TEXECL ${BUSYBOX} cp ${BUSYBOX} /sbin/

		if [ ! -f "/system/etc/.xzdrbusybox" -o ! -x "/system/xbin/lzma" ]; then

			TECHOL "Creating symlinks in /system/xbin to all functions of busybox."
			# Create a symlink for each of the supported commands
			for sym in `${BUSYBOX} --list`; do
				if [ "$sym" = "" ]; then
					continue;
				fi
				TEXECL ${BUSYBOX} ln -sf ${BUSYBOX} /system/xbin/$sym
			done

			TEXECL ${BUSYBOX} touch /system/etc/.xzdrbusybox

		else

			TECHOL "Skipping creation of busybox symlinks."

		fi

		export PATH="/system/xbin"

		TECHOL "Copying recovery files to /sbin"
		TEXECL ${BUSYBOX} cp /system/bin/dualrecovery.sh /sbin/init.sh
		TEXECL ${BUSYBOX} chmod 755 /sbin/init.sh

	else

		TECHOL "Key files missing, exitting!"

		EXIT2CM

	fi

	TEXECL ${BUSYBOX} mount -o remount,ro rootfs /
	TEXECL ${BUSYBOX} mount -o remount,ro /system

fi

# Checking if we can mount an external storage
# The external storage is prefered, cache will now only be used if its absent.

# Create device node if it doesn't exist
if [ ! -b ${BOOTREC_EXTERNAL_SDCARD} ]; then
	TEXECL mknod -m 660 ${BOOTREC_EXTERNAL_SDCARD_NODE}
fi

# Create mountpoint if it doesn't exist
if [ ! -d /storage/sdcard1 ]; then
	TEXECL mount -o remount,rw rootfs /
	TEXECL mkdir -p /storage/sdcard1
	TEXECL mount -o remount,ro rootfs /
fi

# Mount external storage
if [ -b ${BOOTREC_EXTERNAL_SDCARD} ]; then

	# Testing if bootflag is set, that changes the location of the fs type code.
	BOOT=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{print $2}'`
	if [ "${BOOT}" = "*" ]; then
		FSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{print $6}'`
		TXTFSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{for(i=7;i<=NF;++i) printf("%s ", $i)}'`
		TECHOL "### SDCard1 FS found: ${TXTFSTYPE} with code '${FSTYPE}', bootflag was set.";
	else
		FSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{print $5}'`
		TXTFSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{for(i=6;i<=NF;++i) printf("%s ", $i)}'`
		TECHOL "### SDCard1 FS found: ${TXTFSTYPE} with code '${FSTYPE}'.";
	fi

	MOUNTSDCARD ${FSTYPE}
	if [ "$?" -eq "0" ]; then

		# We can! Lets do it, this will keep recovery working even if cache is somehow destroyed.
		TECHOL "### Mounted SDCard1!"
		# Cleanup old chargemon directories
		if [ -d "/cache/${LOGDIR}" ]; then
			TEXECL rm -rf /cache/chargemon
			TEXECL rm -rf /cache/${LOGDIR}
		fi

		DRPATH="/storage/sdcard1/${LOGDIR}"

		if [ ! -d "${DRPATH}" ]; then
			TECHOL "Creating the ${LOGDIR} directory on SDCard1."
			TEXECL mkdir ${DRPATH}
		else
			TECHOL "Removing old chargemon logs..."
			TEXECL rm -f ${DRPATH}/chargemon*
		fi

	else

		TECHOL "### Not mounting SDCard1!";
		DRPATH="/cache/${LOGDIR}"

		if [ ! -d "${DRPATH}" ]; then
			TECHOL "Creating the ${LOGDIR} directory in /cache."
			TEXECL mkdir ${DRPATH}
		fi

	fi

fi

# As a precaution, give users a way out. This works best if the user has an external sdcard.
if [ -f "${DRPATH}/donotrun" ]; then

	TECHOL "Exitting by DNR file.";

	EXIT2CM

fi

if [ ! -d "/system/etc/init.d" ]; then
	TECHOL "No init.d directory found, creating it now!"
	TECHOL "To enable init.d support, set dr.enable.initd to true in XZDR.prop!"
	mkdir /system/etc/init.d
fi

# Initial setup of the XZDR.prop file, only once or whenever the file was removed
if [ ! -f "${DRPATH}/XZDR.prop" ]; then
	TECHOL "Creating XZDR.prop file."
	touch ${DRPATH}/XZDR.prop
	if [ -f "${DRPATH}/default" -a "`cat ${DRPATH}/default`" = "twrp" ]; then
		TECHOL "dr.recovery.boot will be set to TWRP"
		DRSETPROP dr.recovery.boot twrp
		rm -f ${DRPATH}/default
	else
		TECHOL "dr.recovery.boot will be set to TWRP (default)"
		DRSETPROP dr.recovery.boot twrp
	fi
	TECHOL "dr.initd.active will be set to false (default)"
	DRSETPROP dr.initd.active false
	TECHOL "dr.ramdisk.boot will be set to false (default)"
	DRSETPROP dr.ramdisk.boot false
	if [ -f "/system/bin/ramdisk.stock.cpio.lzma" ]; then
		TECHOL "dr.ramdisk.path will /system/bin/ramdisk.stock.cpio.lzma"
		DRSETPROP dr.ramdisk.path /system/bin/ramdisk.stock.cpio.lzma
	else
		TECHOL "dr.ramdisk.path will be empty (default)"
		DRSETPROP dr.ramdisk.path
	fi
	if [ "$ANDROIDVER" = "lollipop" ]; then
		DRSETPROP dr.keep.byeselinux false
	fi
fi

# Initial button setup for existing XZDR.prop files which do not have the input nodes defined.
if [ "$(DRGETPROP dr.pwrkey.node)" = "" -o "$(DRGETPROP dr.pwrkey.node)" = "null" ]; then
	DRSETPROP dr.pwrkey.node $(pwrkeySearch)
fi
if [ "$(DRGETPROP dr.gpiokeys.node)" = "" -o "$(DRGETPROP dr.gpiokeys.node)" = "null" ]; then
	DRSETPROP dr.gpiokeys.node $(gpioKeysSearch)
fi

# Debugging substitution, for ease of use in debugging specific user problems
if [ -e "${DRPATH}/drdebug.sh" ]; then

	# Turn on a blue led, as a visual warning to the user
	SETLED on 0 0 255

	TECHOL "Found debugging script, copying it in place of /sbin/init.sh!"
	TEXECL mount -o remount,rw rootfs /
	cp ${DRPATH}/drdebug.sh /sbin/init.sh
	TEXECL mount -o remount,ro rootfs /
	LOGFILE="XZDebug.log"

	sleep 2

	SETLED off

fi

# Logfile rotation
TECHOL "Logfile rotation..."
if [ -f ${DRPATH}/${LOGFILE} ];then
	TEXECL mv ${DRPATH}/${LOGFILE} ${DRPATH}/${LOGFILE}.old
fi
TEXECL touch ${DRPATH}/${LOGFILE}
TEXECL chmod 660 ${DRPATH}/${LOGFILE}

if [ -e "/sbin/init.sh" -a "$EVENTNODE" != "none" ]; then
	echo "Will be calling /sbin/init.sh with arguments '$DRPATH' and '$LOGFILE'" >> ${PREPLOG}
fi

# Ending log
DATETIME=`${BUSYBOX} date +"%d-%m-%Y %H:%M:%S"`
echo "STOP Dual Recovery STAGE 1 at ${DATETIME}, starting stage 2!" >> ${PREPLOG}

# Copy the preperation log to the main log directory, easy to find for the noobish users...
cp ${PREPLOG} ${DRPATH}/

########
#
#
# Preperations all done, lets continue to recovery!
#
#
#######################################################################

# One last failsafe...
if [ -e "/sbin/init.sh" -a "$EVENTNODE" != "none" ]; then

	export PATH="$_PATH"

	if [ "$ANDROIDVER" = "lollipop" ]; then
		/system/xbin/busybox mount -o remount,rw rootfs /
		exec /sbin/init.sh $DRPATH $LOGFILE
		/system/xbin/busybox mount -o remount,ro rootfs /
	else
		exec /sbin/init.sh $DRPATH $LOGFILE
	fi

else

	EXIT2CM

fi
