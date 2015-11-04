#!/data/local/tmp/recovery/busybox sh
set +x

SWITCH="$1"

_PATH="$PATH"
export PATH="/system/bin:/system/xbin:/sbin"

BUSYBOX="/data/local/tmp/recovery/busybox"

LOGDIR="XZDualRecovery"
SECUREDIR="/system/.XZDualRecovery"

if [ -e "$SECONDARY_STORAGE/" ]; then
	DRPATH="$SECONDARY_STORAGE/${LOGDIR}"
elif [ -e "$EXTERNAL_STORAGE/" ]; then
	DRPATH="$EXTERNAL_STORAGE/${LOGDIR}"
else
	DRPATH="/storage/sdcard1/${LOGDIR}"
fi

if [ ! -d "$DRPATH" ]; then
	${BUSYBOX} mkdir $DRPATH 2>&1 > /dev/null
	if [ ! -d "$DRPATH" ]; then
		DRPATH="/cache/${LOGDIR}"
	fi
fi

if [ ! -f "${DRPATH}/XZDR.prop" ]; then
	${BUSYBOX} touch ${DRPATH}/XZDR.prop
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

  VAR=`${BUSYBOX} grep "$*" /data/local/tmp/recovery/dr.prop | ${BUSYBOX} awk -F'=' '{ print $1 }'`
  PROP=`${BUSYBOX} grep "$*" /data/local/tmp/recovery/dr.prop | ${BUSYBOX} awk -F'=' '{ print $NF }'`

	if [ "$VAR" = "" -a "$PROP" = "" ]; then

		# If it's empty, see if what was requested was a XZDR.prop value!
        	VAR=`${BUSYBOX} grep "$*" ${DRPATH}/XZDR.prop | ${BUSYBOX} awk -F'=' '{ print $1 }'`
        	PROP=`${BUSYBOX} grep "$*" ${DRPATH}/XZDR.prop | ${BUSYBOX} awk -F'=' '{ print $NF }'`

        	if [ "$VAR" = "" -a "$PROP" = "" ]; then

        	        # If it still is empty, try to get it from the build.prop
                	VAR=`${BUSYBOX} grep "$*" /system/build.prop | ${BUSYBOX} awk -F'=' '{ print $1 }'`
                	PROP=`${BUSYBOX} grep "$*" /system/build.prop | ${BUSYBOX} awk -F'=' '{ print $NF }'`

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

ANDROIDVER=`echo "$(DRGETPROP ro.build.version.release) 5.1.0" | ${BUSYBOX} awk '{if ($2 != "" && $1 >= $2) print "lollipop51"; else print "other"}'`
if [ "$ANDROIDVER" = "other" ]; then
	ANDROIDVER=`echo "$(DRGETPROP ro.build.version.release) 5.0.0" | ${BUSYBOX} awk '{if ($2 != "" && $1 >= $2) print "lollipop"; else print "other"}'`
fi

if [ "$SWITCH" = "unrooted" -a "$ANDROIDVER" = "lollipop51" ]; then

	echo ""
	echo "##########################################################"
	echo "#"
	echo "# The unrooted installation does not work on Lollipop 5.1 based ROM's!"
	echo "#"
	echo "# rootkitXperia only works on (some) Lollipop 5.0 ROM's."
	echo "#"
	echo "# The installer will now exit, installation aborted!"
	echo "#"
	echo "#####"
	echo ""

	exit

fi

echo ""
echo "##########################################################"
echo "#"
echo "# Installing XZDR version $(DRGETPROP version) $(DRGETPROP release)"
if [ "$SWITCH" = "unrooted" ]; then
	echo "# using rootkitXperia by cubeundcube, with modifications by zxz0O0."
fi
echo "#"
echo "#####"
echo ""

${BUSYBOX} blockdev --setrw $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system")

echo "Temporarily disabling the RIC service, remount rootfs and /system writable to allow installation."
# Thanks to Androxyde for this method!
RICPATH=$(ps | ${BUSYBOX} grep "bin/ric" | ${BUSYBOX} awk '{ print $NF }')
if [ "$RICPATH" != "" ]; then
	${BUSYBOX} mount -o remount,rw / && mv ${RICPATH} ${RICPATH}c && ${BUSYBOX} pkill -f ${RICPATH}
fi

# Checking android version first, because byeselinux is causing issues with android versions older then lollipop.
# Thanks to zxz0O0 for this method
if [ "$ANDROIDVER" = "lollipop" ]; then
	if [ ! -e "/system/lib/modules/byeselinux.ko" ]; then
		${BUSYBOX} chmod 755 /data/local/tmp/recovery/byeselinux.sh
		/data/local/tmp/recovery/byeselinux.sh
	else
		/system/bin/insmod /system/lib/modules/byeselinux.ko
	fi
else
	echo "This firmware does not require byeselinux, will not install it."
fi

# Thanks to MohammadAG and zxz0O0 for this method, heavily modified by [NUT].
${BUSYBOX} mount -o remount,rw /system 2>&1 > /dev/null
if [ "$?" != "0" ]; then
	echo "Remount of system failed, applying MohammadAG's wp_mod module solution now."
	if [ -e "/system/lib/modules/wp_mod.ko" ]; then
		echo "Module exists in system partition, loading it now."
	        ${BUSYBOX} insmod /system/lib/modules/wp_mod.ko
		if [ "$?" != "0" ]; then
			echo "That module is not accepted by the running kernel, will try to replace it now."
			${BUSYBOX} chmod 755 /data/local/tmp/recovery/sysrw.sh
			/data/local/tmp/recovery/sysrw.sh
		fi
		if [ "$RICPATH" != "" ]; then
			${BUSYBOX} mount -o remount,rw / && mv ${RICPATH} ${RICPATH}c && ${BUSYBOX} pkill -f ${RICPATH}
		fi
		${BUSYBOX} mount -o remount,rw /system
		if [ "$?" != "0" ]; then
			echo "Remount of /system failed again, ABORTING INSTALLATION NOW!"
			exit 1
		fi
	else
		echo "The wp_mod module does not exist, installing it now."
		${BUSYBOX} chmod 755 /data/local/tmp/recovery/sysrw.sh
		/data/local/tmp/recovery/sysrw.sh
		if [ "$RICPATH" != "" ]; then
			${BUSYBOX} mount -o remount,rw / && mv ${RICPATH} ${RICPATH}c && ${BUSYBOX} pkill -f ${RICPATH}
		fi
	fi
fi

# Checking android version first, because byeselinux is causing issues with android versions older then lollipop.
# Thanks to zxz0O0 for this method
if [ "$ANDROIDVER" = "lollipop" ]; then
	if [ ! -e "/system/lib/modules/byeselinux.ko" ]; then
		echo "The byeselinux module does not yet exist on system, installing it now."
		$BUSYBOX cp /data/local/tmp/recovery/byeselinux.ko /system/lib/modules/byeselinux.ko
		$BUSYBOX chmod 644 $SECUREDIR/xbin/byeselinux.ko
	fi
	if [ -e "/system/lib/modules/mhl_sii8620_8061_drv_orig.ko" ]; then
		echo "Removing zxz0O0's byeselinux patch module, restoring the original."
		$BUSYBOX rm -f /system/lib/modules/mhl_sii8620_8061_drv.ko
		$BUSYBOX mv /system/lib/modules/mhl_sii8620_8061_drv_orig.ko /system/lib/modules/mhl_sii8620_8061_drv.ko
	fi
else
	echo "This firmware does not require byeselinux, will not install it."
fi

echo "Creating $SECUREDIR and subfolders."
if [ ! -d "$SECUREDIR" ]; then
	${BUSYBOX} mkdir $SECUREDIR
	${BUSYBOX} chmod 755 $SECUREDIR
fi
if [ ! -d "$SECUREDIR/bin" ]; then
	${BUSYBOX} mkdir $SECUREDIR/bin
	${BUSYBOX} chmod 755 $SECUREDIR/bin
fi
if [ ! -d "$SECUREDIR/xbin" ]; then
	${BUSYBOX} mkdir $SECUREDIR/xbin
	${BUSYBOX} chmod 755 $SECUREDIR/xbin
fi

${BUSYBOX} cp /data/local/tmp/recovery/modulecrcpatch $SECUREDIR/xbin/
${BUSYBOX} chmod 755 $SECUREDIR/xbin/modulecrcpatch
${BUSYBOX} cp /data/local/tmp/recovery/byeselinux.ko $SECUREDIR/xbin/
${BUSYBOX} chmod 644 $SECUREDIR/xbin/byeselinux.ko
${BUSYBOX} cp /data/local/tmp/recovery/wp_mod.ko $SECUREDIR/xbin/
${BUSYBOX} chmod 644 $SECUREDIR/xbin/wp_mod.ko

echo "Copy recovery files to system."
${BUSYBOX} cp /data/local/tmp/recovery/recovery.twrp.cpio.lzma $SECUREDIR/xbin/
#${BUSYBOX} cp /data/local/tmp/recovery/recovery.cwm.cpio.lzma $SECUREDIR/xbin/
${BUSYBOX} cp /data/local/tmp/recovery/recovery.philz.cpio.lzma $SECUREDIR/xbin/
${BUSYBOX} chmod 644 $SECUREDIR/xbin/recovery.twrp.cpio.lzma
#${BUSYBOX} chmod 644 $SECUREDIR/xbin/recovery.cwm.cpio.lzma
${BUSYBOX} chmod 644 $SECUREDIR/xbin/recovery.philz.cpio.lzma

if [ -f "/data/local/tmp/recovery/ramdisk.stock.cpio.lzma" ]; then
	${BUSYBOX} cp /data/local/tmp/recovery/ramdisk.stock.cpio.lzma $SECUREDIR/xbin/
	${BUSYBOX} chmod 644 $SECUREDIR/xbin/ramdisk.stock.cpio.lzma
fi

if [ ! -f "/system/bin/mr.stock" -a -f "/system/bin/mr" ]; then
	echo "Rename stock mr"
	${BUSYBOX} mv /system/bin/mr /system/bin/mr.stock
fi

if [ -f "/system/bin/mr.stock" -a ! -f "/system/bin/mr" ]; then
	echo "Copy mr wrapper script to system."
	${BUSYBOX} cp /data/local/tmp/recovery/mr /system/bin/
	${BUSYBOX} chmod 755 /system/bin/mr
fi

if [ ! -f "/system/bin/chargemon.stock" -a "$(${BUSYBOX} head -n 1 /system/bin/chargemon)" != '#!/system/bin/sh' ]; then
	echo "Rename stock chargemon"
	${BUSYBOX} mv /system/bin/chargemon /system/bin/chargemon.stock
fi

echo "Copy chargemon script to system."
${BUSYBOX} cp /data/local/tmp/recovery/chargemon /system/bin/
${BUSYBOX} chmod 755 /system/bin/chargemon

echo "Copy dualrecovery.sh to system."
${BUSYBOX} cp /data/local/tmp/recovery/dualrecovery.sh $SECUREDIR/xbin/
${BUSYBOX} chmod 755 $SECUREDIR/xbin/dualrecovery.sh

echo "Copy rickiller.sh to system."
${BUSYBOX} cp /data/local/tmp/recovery/rickiller.sh $SECUREDIR/xbin/
${BUSYBOX} chmod 755 $SECUREDIR/xbin/rickiller.sh

echo "Installing NDRUtils to system."
if [ "$ANDROIDVER" = "lollipop" ]; then
	if [ ! -d "/system/app/NDRUtils" ]; then
		${BUSYBOX} mkdir /system/app/NDRUtils
		${BUSYBOX} chmod 755 /system/app/NDRUtils
	fi
	${BUSYBOX} cp /data/local/tmp/recovery/NDRUtils.apk /system/app/NDRUtils/
	${BUSYBOX} chmod 644 /system/app/NDRUtils/NDRUtils.apk
else
	${BUSYBOX} cp /data/local/tmp/recovery/NDRUtils.apk /system/app/
	${BUSYBOX} chmod 644 /system/app/NDRUtils.apk
fi

echo "Copy busybox to system."
${BUSYBOX} cp /data/local/tmp/recovery/busybox $SECUREDIR/xbin/
${BUSYBOX} chmod 755 $SECUREDIR/xbin/busybox

echo "Copy init's *.rc files in to $SECUREDIR."
${BUSYBOX} cp /*.rc $SECUREDIR/

if [ ! -f "${DRPATH}/XZDR.prop" ]; then
	echo "Creating the XZDR properties file."
	${BUSYBOX} touch ${DRPATH}/XZDR.prop
fi

echo "Updating installed version in properties file."
DRSETPROP dr.xzdr.version $(DRGETPROP version) 
DRSETPROP dr.release.type $(DRGETPROP release)

echo "Trying to find and update the gpio-keys event node."
GPIOINPUTDEV="$(gpioKeysSearch)"
echo "Found and will be using ${GPIOINPUTDEV}!"
DRSETPROP dr.gpiokeys.node ${GPIOINPUTDEV}

echo "Trying to find and update the power key event node."
PWRINPUTDEV="$(pwrkeySearch)"
echo "Found and will be monitoring ${PWRINPUTDEV}!"
DRSETPROP dr.pwrkey.node ${PWRINPUTDEV}

if [ "$ANDROIDVER" = "lollipop" ]; then
	if [ "$(DRGETPROP dr.keep.byeselinux)" != "true" ]; then
	        echo "XZDualRecovery will unload byeselinux every boot."
	        DRSETPROP dr.keep.byeselinux false
	else
	        echo "XZDualRecovery will leave byeselinux loaded."
	        DRSETPROP dr.keep.byeselinux true
	fi
fi

FOLDER1=/sdcard/clockworkmod/
FOLDER2=/sdcard1/clockworkmod/
FOLDER3=/cache/recovery/

echo "Speeding up CWM backups."
if [ ! -e "$FOLDER1" ]; then
	${BUSYBOX} mkdir /sdcard/clockworkmod/
	${BUSYBOX} touch /sdcard/clockworkmod/.hidenandroidprogress
else
	${BUSYBOX} touch /sdcard/clockworkmod/.hidenandroidprogress
fi

if [ ! -e "$FOLDER2" ]; then
	${BUSYBOX} mkdir /sdcard1/clockworkmod/
	${BUSYBOX} touch /sdcard1/clockworkmod/.hidenandroidprogress
else
	${BUSYBOX} touch /sdcard1/clockworkmod/.hidenandroidprogress
fi

echo "Make sure firstboot goes to recovery."
if [ -e "$FOLDER3" ];
then
	${BUSYBOX} touch /cache/recovery/boot
else
	${BUSYBOX} mkdir /cache/recovery/
	${BUSYBOX} touch /cache/recovery/boot
fi

DRSETPROP dr.xzdr.version $(DRGETPROP version)
DRSETPROP dr.release.type $(DRGETPROP release)

if [ "$SWITCH" = "unrooted" ]; then

	if [ ! -d "$SECUREDIR" ]; then

		echo ""
		echo "============================================="
		echo "Installation Failed!"
		echo "============================================="
		echo ""
		${BUSYBOX} sync
		${BUSYBOX} ls -la /system
		${BUSYBOX} mount

	else

		${BUSYBOX} sync

	fi

	/system/bin/am start -a android.intent.action.REBOOT 2>&1 > /dev/null
	if [ "$?" != "0" ]; then

		reboot

	fi

else

	echo ""
	echo "============================================="
	echo "DEVICE WILL NOW TRY A DATA SAFE REBOOT!"
	echo "============================================="
	echo ""

	/system/bin/am start -a android.intent.action.REBOOT 2>&1 > /dev/null
	if [ "$?" != "0" ]; then

		echo ""
		echo "============================================="
		echo "If you want the installer to clean up after itself,"
		echo "reboot to system after entering recovery for the first time!"
		echo "============================================="
		echo ""

		reboot

	else

		echo ""
		echo "============================================="
		echo "Your installation has already cleaned up after"
		echo "itself if you see the install.bat/install.sh exit."
		echo "============================================="
		echo ""

	fi

fi
