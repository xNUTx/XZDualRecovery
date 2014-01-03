#!/sbin/busybox sh

/sbin/busybox touch /tmp/timedaemon

/sbin/busybox mount -t ext4 -o ro,barrier=1,discard /dev/block/platform/msm_sdcc.1/by-name/system /system 2>&1 > /tmp/timedaemon

# Initialize system clock.
if [ "$(getprop persist.sys.timezone)" != "" ]; then

	export TZ=$(getprop persist.sys.timezone)

fi

/sbin/time_daemon &
/sbin/busybox sleep 3
/sbin/busybox pkill -f /sbin/time_daemon
/sbin/busybox umount /system
