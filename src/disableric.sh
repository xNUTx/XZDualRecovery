#!/system/xbin/busybox sh
/system/xbin/busybox mount -o remount,rw /
/system/xbin/busybox mount -t securityfs -o nosuid,nodev,noexec /sys/kernel/security
/system/xbin/busybox mkdir -p /sys/kernel/security/sony_ric
/system/xbin/busybox chmod 755 /sys/kernel/security/sony_ric
/system/xbin/busybox echo 0 > /sys/kernel/security/sony_ric/enable
/system/xbin/busybox mount -o remount,ro /
