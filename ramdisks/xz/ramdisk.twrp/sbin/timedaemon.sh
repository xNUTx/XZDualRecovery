#!/sbin/busybox sh

echo $(/sbin/busybox date) > /tmp/timedaemon

/sbin/busybox mount -t ext4 -o ro,barrier=1,discard /dev/block/platform/msm_sdcc.1/by-name/system /system 2>&1 >> /tmp/timedaemon

cp /system/bin/time_daemon /sbin/
/sbin/busybox find /system -name "libqmi_cci.so" -exec cp {} /sbin/ \;
/sbin/busybox find /system -name "libqmi_client_qmux.so" -exec cp {} /sbin/ \;
/sbin/busybox find /system -name "libqmi_common_so.so" -exec cp {} /sbin/ \;
/sbin/busybox find /system -name "libqmi_encdec.so" -exec cp {} /sbin/ \;
/sbin/busybox find /system -name "libdiag.so" -exec cp {} /sbin/ \;

# Initialize system clock.
if [ "$(getprop persist.sys.timezone)" != "" ]; then

	export TZ=$(getprop persist.sys.timezone)
	echo $(getprop persist.sys.timezone) >> /tmp/timedaemon

else

	export TZ="GMT+1"
	echo "Set something random..." >> /tmp/timedaemon

fi

/system/bin/time_daemon &
/sbin/busybox sleep 3
/sbin/busybox pkill -f /system/bin/time_daemon
/sbin/busybox umount /system

echo $(/sbin/busybox date) >> /tmp/timedaemon
