#!/system/bin/sh

touch /data/local/tmp/recovery/zxz_run
/data/local/tmp/recovery/findricaddr | /data/local/tmp/recovery/busybox tail -n2 | /data/local/tmp/recovery/busybox head -n1 | /data/local/tmp/recovery/busybox cut -d= -f2 > /data/local/tmp/recovery/ricaddr
chmod 777 /data/local/tmp/recovery/ricaddr
/data/local/tmp/recovery/writekmem `/data/local/tmp/recovery/busybox cat /data/local/tmp/recovery/ricaddr` 0

mount -o remount,rw /system
exit
