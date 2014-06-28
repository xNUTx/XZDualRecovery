#!/system/bin/sh


touch /data/local/tmp/zxz_run
touch /data/local/tmp/ricaddr
chmod 777 /data/local/tmp/ricaddr

findricaddr=`/data/local/tmp/findricaddr`
if [ "$?" = "0" ]; then
	echo "$findricaddr" | /data/local/tmp/busybox tail -n1 | /data/local/tmp/busybox cut -d= -f2 > /data/local/tmp/ricaddr
else
	echo 0 > /proc/sys/kernel/kptr_restrict
	kallsyms_RIC=`/data/local/tmp/busybox cat /proc/kallsyms | /data/local/tmp/busybox grep "sony_ric_enabled" | /data/local/tmp/busybox grep "T" | /data/local/tmp/busybox cut -d' ' -f1`
	RIC_dump=`dd if=/dev/kmem skip=$(( 0x$kallsyms_RIC )) bs=1 count=16 | /data/local/tmp/busybox hexdump`
	echo -n `echo $RIC_dump | /data/local/tmp/busybox cut -d' ' -f9` > /data/local/tmp/ricaddr
	echo `echo $RIC_dump | /data/local/tmp/busybox cut -d' ' -f8` >> /data/local/tmp/ricaddr
fi

/data/local/tmp/writekmem `/data/local/tmp/busybox cat /data/local/tmp/ricaddr` 0

mount -o remount,rw /system
exit