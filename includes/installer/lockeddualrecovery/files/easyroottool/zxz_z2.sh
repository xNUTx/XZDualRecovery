#!/system/bin/sh

touch /data/local/tmp/zxz_run
/data/local/tmp/findricaddr | /data/local/tmp/busybox tail -n2 | /data/local/tmp/busybox head -n1 | /data/local/tmp/busybox cut -d= -f2 > /data/local/tmp/ricaddr
chmod 777 /data/local/tmp/ricaddr
/data/local/tmp/writekmem `/data/local/tmp/busybox cat /data/local/tmp/ricaddr` 0

mount -o remount,rw /system
exit