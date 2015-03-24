#!/sbin/busybox sh
set +x
_PATH="$PATH"

# Constants
LOGDIR="XZDualRecovery"
PREPLOG="/xztmp/boot.log"
XZDRLOG="XZDualRecovery.log"
BUSYBOX="/sbin/busybox"

DRLOG="$PREPLOG"

MOUNTS=$(${BUSYBOX} mount)

${BUSYBOX} mount -o remount,rw / 2>&1 >> /proc/kmsg

if [ "$(`${BUSYBOX} mountpoint -q /dev`; ${BUSYBOX} echo $?)" = "1" ]; then
	${BUSYBOX} mount -t devtmpfs devtmpfs /dev
	MOUNTEDDEV=true
fi
if [ "$(`${BUSYBOX} mountpoint -q /proc`; ${BUSYBOX} echo $?)" = "1" ]; then
	${BUSYBOX} mount -t proc proc /proc
	MOUNTEDPROC=true
fi
if [ "$(`${BUSYBOX} mountpoint -q /sys`; ${BUSYBOX} echo $?)" = "1" ]; then
	${BUSYBOX} mount -t sysfs sysfs /sys
	MOUNTEDSYS=true
fi

echo "testmessage" >> /proc/kmsg

${BUSYBOX} chcon -t system_file /sbin/busybox 2>&1 >> /proc/kmsg
${BUSYBOX} chcon -t system_file /sbin/xzdr.sh 2>&1 >> /proc/kmsg

${BUSYBOX} dd if=/dev/zero of=/test bs=1024 count=1024 2>&1 >> /proc/kmsg

${BUSYBOX} mkdir -m 777 /xztmp
${BUSYBOX} mount -t tmpfs tmpfs /xztmp

cd /

${BUSYBOX} date > ${DRLOG}
${BUSYBOX} echo $MOUNTS >> ${DRLOG}

# create directories and setup the temporary bin path
if [ ! -d "/system" ]; then
	${BUSYBOX} mkdir -m 755 -p /system
fi
if [ ! -d "/cache" ]; then
	${BUSYBOX} mkdir -m 755 -p /cache
fi
if [ ! -d "/storage/sdcard1" ]; then
	${BUSYBOX} mkdir -m 777 -p /storage/sdcard1
fi

${BUSYBOX} blockdev --setrw $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system")
${BUSYBOX} blockdev --setrw $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "cache")
${BUSYBOX} mount -w $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system") /system
${BUSYBOX} mount -w $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "cache") /cache

${BUSYBOX} mkdir -m 777 /drbin
${BUSYBOX} mount -t tmpfs tmpfs /drbin
${BUSYBOX} echo "Install busybox to /drbin..." >> ${DRLOG}
#${BUSYBOX} cp ${BUSYBOX} /drbin/
${BUSYBOX} chmod 755 /sbin
${BUSYBOX} chmod 755 /sbin/busybox

#BUSYBOX="/drbin/busybox"

${BUSYBOX} --list >> ${DRLOG}

# Here we setup a binaries folder, to make the rest of the script readable and easy to use. It will allow us to slim it down too.
${BUSYBOX} echo "Creating symlinks in /drbin to all functions of busybox." >> ${DRLOG}
# Create a symlink for each of the supported commands
for sym in `${BUSYBOX} --list`; do
#	echo "Linking ${BUSYBOX} to /drbin/$sym" >> ${DRLOG}
	${BUSYBOX} ln -sf ${BUSYBOX} /drbin/$sym
done

export PATH="/drbin:/sbin"

# Function definitions
# They rely on the busybox setup being complete, do not try to use them before it did.
ECHOL(){
  _TIME=`date +"%H:%M:%S"`
  echo "${_TIME} >> $*" >> ${DRLOG}
  return 0
}

EXECL(){
  _TIME=`date +"%H:%M:%S"`
  echo "${_TIME} >> $*" >> ${DRLOG}
  $* 2>&1 >> ${DRLOG}
  _RET=$?
  echo "${_TIME} >> RET=${_RET}" >> ${DRLOG}
  return ${_RET}
}

MOUNTSDCARD(){
        case $* in
                06|6|0B|b|0C|c|0E|e) EXECL mount -t vfat /dev/block/mmcblk1p1 /storage/sdcard1; return $?;;
                07|7) EXECL insmod /system/lib/modules/nls_utf8.ko;
                      EXECL insmod /system/lib/modules/texfat.ko;
                      EXECL mount -t texfat /dev/block/mmcblk1p1 /storage/sdcard1;
                      return $?;;
                83) PTYPE=$(blkid /dev/block/mmcblk1p1 | awk -F' ' '{ print $NF }' | awk -F'[\"=]' '{ print $3 }');
                    EXECL mount -t $PTYPE /dev/block/mmcblk1p1 /storage/sdcard1;
                    return $?;;
                 *) return 1;;
        esac
        ECHOL "### MOUNTSDCARD did not run with a parameter!";
        return 1
}

# Set the led on at a specified color, or off.
# Syntax: SETLED on R G B
SETLED() {
        if [ "$1" = "on" ]; then
                ECHOL "Turn on LED R: $2 G: $3 B: $4"
                echo "$2" > ${BOOTREC_LED_RED}
                echo "$3" > ${BOOTREC_LED_GREEN}
                echo "$4" > ${BOOTREC_LED_BLUE}
        else
                ECHOL "Turn off LED"
                echo "0" > ${BOOTREC_LED_RED}
                echo "0" > ${BOOTREC_LED_GREEN}
                echo "0" > ${BOOTREC_LED_BLUE}
        fi
}

# Find the gpio-keys node, to listen on the right input event
gpioKeysSearch() {
        ECHOL "Trying to find the gpio-keys event node."
        for INPUTUEVENT in `find /sys/devices \( -path "*gpio*" -path "*keys*" -a -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

                INPUTDEV=$(grep "DEVNAME=" ${INPUTUEVENT} | sed 's/DEVNAME=//')

                if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
                        ECHOL "Found and will be using /dev/${INPUTDEV}!"
                        echo "/dev/${INPUTDEV}"
                        return 0
                fi

        done
}

# Find the power key node, to listen on the right input event
pwrkeySearch() {
        ECHOL "Trying to find the power key event node."
        # pm8xxx (xperia Z and similar)
        for INPUTUEVENT in `find /sys/devices \( -path "*pm8xxx*" -path "*pwrkey*" -a -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

                INPUTDEV=$(grep "DEVNAME=" ${INPUTUEVENT} | sed 's/DEVNAME=//')

                if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
                        ECHOL "Found and will be monitoring /dev/${INPUTDEV}!"
                        echo "/dev/${INPUTDEV}"
                        return 0
                fi

        done
        # qpnp_pon (xperia Z1 and similar)
        for INPUTUEVENT in `find $(find /sys/devices/ -name "name" -exec grep -l "qpnp_pon" {} \; | awk -F '/' 'sub(FS $NF,x)') \( -path "*input?*" -a -path "*event?*" -a -name "uevent" \)`; do

                INPUTDEV=$(grep "DEVNAME=" ${INPUTUEVENT} | sed 's/DEVNAME=//')

                if [ -e "/dev/$INPUTDEV" -a "$INPUTDEV" != "" ]; then
                        ECHOL "Found and will be monitoring /dev/${INPUTDEV}!"
                        echo "/dev/${INPUTDEV}"
                        return 0
                fi

        done
}

DRGETPROP() {

        # If it's empty, see if what was requested was a XZDR.prop value!
        VAR=`grep "$*" ${DRPATH}/XZDR.prop | awk -F'=' '{ print $1 }'`
        PROP=`grep "$*" ${DRPATH}/XZDR.prop | awk -F'=' '{ print $NF }'`

        if [ "$VAR" != "" ]; then
                echo $PROP
        else
                echo "false"
        fi

}

DRSETPROP() {

        # We want to set this only if the XZDR.prop file exists...
        if [ ! -f "${DRPATH}/XZDR.prop" ]; then
                return 0
        fi

        PROP=$(DRGETPROP $1)

        if [ "$PROP" != "false" ]; then
                sed -i 's|'$1'=[^ ]*|'$1'='$2'|' ${DRPATH}/XZDR.prop
        else
                echo "$1=$2" >> ${DRPATH}/XZDR.prop
        fi
        return 0

}

# drbin is now the only path, with all the busybox functions linked, it's safe to use normal commands from here on.
# Using ECHOL from here on adds all the lines to the XZDR log file.
# Using EXECL from here on will echo the command and it's result in to the logfile.
# Not all commands will allow this to be used, so sometimes you will have to do without.

# Attempting to mount the external sdcard.
BOOT=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{print $2}'`
if [ "${BOOT}" = "*" ]; then
	FSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{print $6}'`
	TXTFSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{for(i=7;i<=NF;++i) printf("%s ", $i)}'`
	ECHOL "### SDCard1 FS found: ${TXTFSTYPE} with code '${FSTYPE}', bootflag was set."
else
	FSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{print $5}'`
	TXTFSTYPE=`fdisk -l /dev/block/mmcblk1 | grep "/dev/block/mmcblk1p1" | awk '{for(i=6;i<=NF;++i) printf("%s ", $i)}'`
	ECHOL "### SDCard1 FS found: ${TXTFSTYPE} with code '${FSTYPE}'."
fi

if [ "$(mount | grep 'sdcard1' | wc -l)" = "0" ]; then

	MOUNTSDCARD ${FSTYPE}
	if [ "$?" -eq "0" ]; then

		echo "### Mounted SDCard1!" >> ${DRLOG}

#		DRPATH="/storage/sdcard1/${LOGDIR}"

		if [ ! -d "${DRPATH}" ]; then
			echo "Creating the ${LOGDIR} directory on SDCard1." >> ${DRLOG}
			mkdir -m 777 -p ${DRPATH}
		fi

	else

		echo "### Not mounting SDCard1, using /cache instead!" >> ${DRLOG}

		# Mount cache, it is the XZDR fallback
		if [ "$(mount | grep 'cache' | wc -l)" = "0" ]; then
			EXECL mount /cache
		fi

#		DRPATH="/cache/${LOGDIR}"

		if [ ! -d "${DRPATH}" ]; then
			echo "Creating the ${LOGDIR} directory in /cache." >> ${DRLOG}
			mkdir -m 777 -p ${DRPATH}
		fi

	fi

fi

MOUNTS=$(mount)
ECHOL "DEBUGINFO=Current mounted filesystems:"
ECHOL $MOUNTS

ECHOL $(whoami)

# Rotate and merge logs
ECHOL "Logfile rotation..."
if [ -f "${DRPATH}/${XZDRLOG}" ]; then
	EXECL mv ${DRPATH}/${XZDRLOG} ${DRPATH}/${XZDRLOG}.old
fi
EXECL touch ${DRPATH}/${XZDRLOG}
EXECL chmod 660 ${DRPATH}/${XZDRLOG}
cat ${DRLOG} > ${DRPATH}/${XZDRLOG}
#rm ${DRLOG}
DRLOG="${DRPATH}/${XZDRLOG}"

# Initial setup of the XZDR.prop file, only once or whenever the file was removed
if [ ! -f "${DRPATH}/XZDR.prop" ]; then
        ECHOL "Creating XZDR.prop file."
        touch ${DRPATH}/XZDR.prop
        ECHOL "dr.recovery.boot will be set to TWRP (default)"
        DRSETPROP dr.recovery.boot twrp
        ECHOL "dr.initd.active will be set to false (default)"
        DRSETPROP dr.initd.active false
        DRSETPROP dr.gpiokeys.node $(gpioKeysSearch)
        DRSETPROP dr.pwrkey.node $(pwrkeySearch)
fi

# Initial button setup for existing XZDR.prop files which do not have the input nodes defined.
if [ "$(DRGETPROP dr.pwrkey.node)" = "" -o "$(DRGETPROP dr.pwrkey.node)" = "false" ]; then
        DRSETPROP dr.pwrkey.node $(pwrkeySearch)
fi
if [ "$(DRGETPROP dr.gpiokeys.node)" = "" -o "$(DRGETPROP dr.gpiokeys.node)" = "false" ]; then
        DRSETPROP dr.gpiokeys.node $(gpioKeysSearch)
fi

# Base setup, find the right led nodes.
BOOTREC_LED_RED="/sys/class/leds/$(ls -1 /sys/class/leds|grep red)/brightness"
BOOTREC_LED_GREEN="/sys/class/leds/$(ls -1 /sys/class/leds|grep green)/brightness"
BOOTREC_LED_BLUE="/sys/class/leds/$(ls -1 /sys/class/leds|grep blue)/brightness"
EVENTNODE=$(DRGETPROP dr.gpiokeys.node)
RECOVERYBOOT="false"
KEYCHECK="false"

if [ "$(grep 'warmboot=0x77665502' /proc/cmdline | wc -l)" = "1" ]; then

        ECHOL "Reboot 'recovery' trigger found."
        RECOVERYBOOT="true"

elif [ -f "/cache/recovery/boot" -o -f "${DRPATH}/boot" ]; then

        ECHOL "Recovery 'boot file' trigger found."
        RECOVERYBOOT="true"

        if [ -f "/cache/recovery/boot" ]; then
                EXECL rm -f /cache/recovery/boot
        fi

        if [ -f "${DRPATH}/boot" ]; then
                EXECL rm -f ${DRPATH}/boot
        fi

else

        ECHOL "DR Keycheck..."
        cat ${EVENTNODE} > /dev/keycheck &

        # Vibrate to alert user to make a choice
        ECHOL "Trigger vibrator"
        echo 150 > /sys/class/timed_output/vibrator/enable
        usleep 300000
        echo 150 > /sys/class/timed_output/vibrator/enable

        # Turn on green LED as a visual cue
        SETLED on 0 255 0

        EXECL sleep 3

        hexdump < /dev/keycheck > /dev/keycheckout

        VOLUKEYCHECK=`cat /dev/keycheckout | grep '0001 0073' | wc -l`
        VOLDKEYCHECK=`cat /dev/keycheckout | grep '0001 0072' | wc -l`

        if [ "$VOLUKEYCHECK" != "0" -a "$VOLDKEYCHECK" = "0" ]; then
                ECHOL "Recorded VOL-UP on ${EVENTNODE}!"
                KEYCHECK="UP"
        elif [ "$VOLDKEYCHECK" != "0" -a "$VOLUKEYCHECK" = "0" ]; then
                ECHOL "Recorded VOL-DOWN on ${EVENTNODE}!"
                KEYCHECK="DOWN"
        elif [ "$VOLUKEYCHECK" != "0" -a "$VOLDKEYCHECK" != "0" ]; then
                ECHOL "Recorded BOTH VOL-UP & VOL-DOWN on ${EVENTNODE}! Making the choice to go to the UP target..."
                KEYCHECK="UP"
        fi

        EXECL killall cat

        EXECL rm -f /dev/keycheck
        EXECL rm -f /dev/keycheckout

        if [ "$KEYCHECK" != "false" ]; then

                ECHOL "Recovery 'volume button' trigger found."
                RECOVERYBOOT="true"

        fi

fi

if [ "$RECOVERYBOOT" = "true" ]; then

	# kill all services
	for i in $(getprop | grep init.svc | sed -r 's/^\[init\.svc\.(.+)\]:.*$/\1/'); do
		ECHOL "stopping ${i}"
		stop ${i}
		sleep 1
	done

        # Recovery boot mode notification
        SETLED on 255 0 255

        cd /

        # reboot recovery trigger or boot file found, no keys pressed: read what recovery to use
        if [ "$KEYCHECK" = "false" ]; then
                RECLOAD="$(DRGETPROP dr.recovery.boot)"
                RECLOG="Booting to ${RECLOAD}..."
        fi

        # Prepare PhilZ recovery - by button press
        if [ "$KEYCHECK" = "UP" ]; then
                RECLOAD="philz"
                RECLOG="Booting recovery by keypress, booting to PhilZ Touch..."
        fi

        # Prepare TWRP recovery - by button press
        if [ "$KEYCHECK" = "DOWN" ]; then
                RECLOAD="twrp"
                RECLOG="Booting recovery by keypress, booting to TWRP..."
        fi

	if [ "$KEYCHECK" != "false" ]; then
		DRSETPROP dr.recovery.boot $RECLOAD
	fi
	RAMDISK="/sbin/recovery.$RECLOAD.cpio"
	PACKED="false"

	if [ ! -f "$RAMDISK" -a -f "/sbin/recovery.${RECLOAD}.cpio.lzma" ]; then
		ECHOL "CPIO Archive not found, accepting it probably is an lzma version!"
		EXECL cp /sbin/recovery.${RECLOAD}.cpio.lzma /xztmp/
		EXECL lzma -d /xztmp/recovery.${RECLOAD}.cpio.lzma
		RAMDISK="/xztmp/recovery.$RECLOAD.cpio"
	else
		ECHOL "Recovery ramdisk missing!"
	fi

	EXECL mkdir -m 777 /recovery
	EXECL mount -t tmpfs tmpfs /recovery
	EXECL cd /recovery

	# Unmount all active filesystems
	EXECL umount -l /system
        EXECL umount -l /dev/cpuctl
        EXECL umount -l /dev/pts
        EXECL umount -l /mnt/asec
        EXECL umount -l /mnt/obb
        EXECL umount -l /mnt/qcks
        EXECL umount -l /mnt/idd        # Appslog
        EXECL umount -l /data/idd       # Appslog
        EXECL umount -l /data           # Userdata
        EXECL umount -l /lta-label      # LTALabel

	# Unpack the ramdisk image
	cpio -i -u < $RAMDISK

	EXECL cp -a /sbin/2nd-init /recovery/sbin/
	EXECL cp -a /sbin/init.sh /recovery/sbin/
	EXECL cp -a /sbin/taskset /recovery/sbin/

	SETLED off

	# Executing INIT.
	ECHOL "Executing recovery init, have fun!"

	# Here the log dies.
	/sbin/busybox umount -l /cache
	/sbin/busybox umount -l /storage/sdcard1
#	/sbin/busybox umount -l /drbin
#	/sbin/busybox rm -r /drbin
	/sbin/busybox chroot /recovery /sbin/init.sh
	exit

fi

SETLED off

ECHOL "Booting Android."

#/sbin/busybox umount /drbin
/sbin/busybox umount /system
/sbin/busybox umount /cache
/sbin/busybox umount -l /storage/sdcard1
export PATH="$_PATH"
#/sbin/busybox rm -r /drbin

exit 0
