/system/bin/mount -o remount,rw rootfs /
/system/bin/mv /sbin/ric /sbin/ricc
/system/bin/mount -t securityfs -o nosuid,nodev,noexec securityfs /sys/kernel/security
/system/xbin/busybox mkdir -p /sys/kernel/security/sony_ric
/system/bin/chmod 755 /sys/kernel/security/sony_ric
/system/bin/echo 0 > /sys/kernel/security/sony_ric/enable
/system/bin/mount -o remount,ro rootfs /
