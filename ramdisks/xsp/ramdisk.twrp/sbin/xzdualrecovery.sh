#!/sbin/busybox sh

# Backup original LD_LIBRARY_PATH value to restore it later.
_LDLIBPATH="$LD_LIBRARY_PATH"
# Backup original PATH value to restore later
_PATH="$PATH"

export LD_LIBRARY_PATH=".:/sbin:/system/vendor/lib:/system/lib"
export PATH="/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin"

BOOTREC_LED_RED="/sys/class/leds/$(/sbin/busybox ls -1 /sys/class/leds|grep red)/brightness"
BOOTREC_LED_GREEN="/sys/class/leds/$(/sbin/busybox ls -1 /sys/class/leds|grep green)/brightness"
BOOTREC_LED_BLUE="/sys/class/leds/$(/sbin/busybox ls -1 /sys/class/leds|grep blue)/brightness"

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

FLASHLED() {
	SETLED on 255 0 0
	sleep 1
	SETLED off
	sleep 1
	FLASHLED
}

for LOCKINGPID in `/sbin/busybox lsof | awk '{print $1" "$2}' | grep -E "/bin|/system|/data|/cache" | awk '{print $1}'`; do
	BINARY=$(ps | grep " $LOCKINGPID " | grep -v "grep" | awk '{print $5}')
        echo "File ${BINARY} is locking a critical partition running as PID ${LOCKINGPID}, killing it now!" >> /tmp/xperiablfix.log
	kill -9 $LOCKINGPID
done

REMAINING=$(/sbin/busybox lsof | awk '{print $1" "$2}' | grep -E "/bin|/system|/data|/cache" | wc -l)
if [ $REMAINING -gt 0 ]; then
	FLASHLED
fi

echo "Anti-Filesystem-Lock completed." >> /tmp/xzdr.log

echo "Correcting system time: $(/sbin/busybox date)" >> /tmp/xzdr.log

SYSTEM=$(find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system")
USERDATA=$(find /dev/block/platform/msm_sdcc.1/by-name/ -iname "userdata")

/sbin/busybox mount -t ext4 -o rw,barrier=1,discard $SYSTEM /system 2>&1 >> /tmp/xzdr.log
/sbin/busybox mount -t ext4 -o rw,barrier=1,discard $USERDATA /data 2>&1 >> /tmp/xzdr.log

#cp /system/bin/time_daemon /sbin/
#/sbin/busybox find /system -name "libqmi_cci.so" -exec cp {} /sbin/ \;
#/sbin/busybox find /system -name "libqmi_client_qmux.so" -exec cp {} /sbin/ \;
#/sbin/busybox find /system -name "libqmi_common_so.so" -exec cp {} /sbin/ \;
#/sbin/busybox find /system -name "libqmi_encdec.so" -exec cp {} /sbin/ \;
#/sbin/busybox find /system -name "libdiag.so" -exec cp {} /sbin/ \;

# Initialize system clock.
if [ "$(getprop persist.sys.timezone)" != "" ]; then

	export TZ=$(getprop persist.sys.timezone)
	echo "Set $(getprop persist.sys.timezone) timezone..." >> /tmp/xzdr.log

else

	export TZ="GMT"
	echo "Set GMT timezone..." >> /tmp/xzdr.log

fi

/system/bin/time_daemon &

/sbin/busybox sleep 2

/sbin/busybox pkill -f /system/bin/time_daemon 2>&1 >> /tmp/xzdr.log

/sbin/busybox sleep 2

/sbin/busybox umount -l /system 2>&1 >> /tmp/xzdr.log
/sbin/busybox umount -l /data 2>&1 >> /tmp/xzdr.log

echo "Corrected system time: $(/sbin/busybox date)" >> /tmp/xzdr.log

# Returning values to their original settings
export LD_LIBRARY_PATH="$_LDLIBPATH"
export PATH="$_PATH"

exit 0
