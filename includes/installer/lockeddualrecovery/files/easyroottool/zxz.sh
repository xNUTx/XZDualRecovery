#!/system/bin/sh

BUSYBOX="/data/local/tmp/recovery/busybox"

installModule(){
	rm /data/local/tmp/ricaddr
	rm /data/local/tmp/writekmem
	${BUSYBOX} blockdev --setrw $(${BUSYBOX} find /dev/block/platform/msm_sdcc.1/by-name/ -iname "system")
	mount -o remount,rw /system
	cp /data/local/tmp/wp_mod.ko /system/lib/modules/
	insmod /system/lib/modules/wp_mod.ko
	return 0
}

touch /data/local/tmp/zxz_run
touch /data/local/tmp/ricaddr
chmod 777 /data/local/tmp/ricaddr

RICPATH=`ps | /data/local/tmp/busybox grep "bin/ric" | /data/local/tmp/busybox awk '{ print $NF }'`
if [ "$RICPATH" != "" ]; then
	mount -o remount,rw / && mv ${RICPATH} ${RICPATH}c && /data/local/tmp/busybox pkill -f ${RICPATH}
fi

kmem_exists=`ls /dev/kmem`
if [ "$kmem_exists" != "/dev/kmem: No such file or directory" ]; then
	findricaddr=`/data/local/tmp/findricaddr`
	if [ "$?" = "0" ]; then
		echo "$findricaddr" | /data/local/tmp/busybox tail -n1 | /data/local/tmp/busybox cut -d= -f2 > /data/local/tmp/ricaddr
	else
		echo 0 > /proc/sys/kernel/kptr_restrict
		kallsyms_RIC=`/data/local/tmp/busybox cat /proc/kallsyms | /data/local/tmp/busybox grep "sony_ric_enabled" | /data/local/tmp/busybox grep "T" | /data/local/tmp/busybox cut -d' ' -f1`
		RIC_dump=`dd if=/dev/kmem skip=$(( 0x$kallsyms_RIC )) bs=1 count=16 | /data/local/tmp/busybox hexdump 2> /dev/null`
		echo -n `echo $RIC_dump | /data/local/tmp/busybox cut -d' ' -f9` > /data/local/tmp/ricaddr
		echo `echo $RIC_dump | /data/local/tmp/busybox cut -d' ' -f8` >> /data/local/tmp/ricaddr
	fi

	RIC_addr=`/data/local/tmp/busybox cat /data/local/tmp/ricaddr`
	if [ ${#kernelver} -gt 7 ]; then
		/data/local/tmp/writekmem `/data/local/tmp/busybox cat /data/local/tmp/ricaddr` 0 &> /dev/null
	else
		installModule
	fi
else
	installModule
fi

exit
