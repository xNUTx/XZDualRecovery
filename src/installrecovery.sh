#!/system/bin/sh
set +x

_PATH="$PATH"
export PATH="/system/bin:/system/xbin:/sbin"

BUSYBOX=""

DRGETPROP() {
	PROP=`${BUSYBOX} grep "$*" /data/local/tmp/recovery/dr.prop | ${BUSYBOX} awk -F'=' '{ print $NF }'`
	echo $PROP
}

if [ -x "/system/xbin/busybox" -a "`/system/xbin/busybox --list | /data/local/tmp/recovery/busybox grep pkill | /data/local/tmp/recovery/busybox wc -l`" = "1" ]; then
	BUSYBOX="/system/xbin/busybox"
elif [ -x "/system/bin/busybox" -a "`/system/bin/busybox --list | /data/local/tmp/recovery/busybox grep pkill | /data/local/tmp/recovery/busybox wc -l`" = "1" ]; then
	BUSYBOX="/system/bin/busybox"
else
	BUSYBOX="/data/local/tmp/recovery/busybox"
fi

echo ""
echo "##########################################################"
echo "#"
echo "# Installing DR version $(DRGETPROP version)"
echo "#"
echo "#####"
echo ""

echo "Temporarily disabling the RIC service, remount rootfs and /system writable to allow installation."
# Thanks to Androxyde for this method!
RICPATH=$(ps | ${BUSYBOX} grep "bin/ric" | ${BUSYBOX} awk '{ print $NF }')
if [ "$RICPATH" != "" ]; then
	${BUSYBOX} mount -o remount,rw / && mv ${RICPATH} ${RICPATH}c && ${BUSYBOX} pkill -f ${RICPATH}
fi
sleep 2
${BUSYBOX} mount -o remount,rw /
${BUSYBOX} mount -o remount,rw /system

echo "Copy recovery files to system."
${BUSYBOX} cp /data/local/tmp/recovery/recovery.twrp.cpio.lzma /system/bin/
${BUSYBOX} cp /data/local/tmp/recovery/recovery.cwm.cpio.lzma /system/bin/
${BUSYBOX} cp /data/local/tmp/recovery/recovery.philz.cpio.lzma /system/bin/
${BUSYBOX} chmod 644 /system/bin/recovery.twrp.cpio.lzma
${BUSYBOX} chmod 644 /system/bin/recovery.cwm.cpio.lzma
${BUSYBOX} chmod 644 /system/bin/recovery.philz.cpio.lzma

if [ -f "/data/local/tmp/recovery/ramdisk.stock.cpio.lzma" ]; then
	${BUSYBOX} cp /data/local/tmp/recovery/ramdisk.stock.cpio.lzma /system/bin/
	${BUSYBOX} chmod 644 /system/bin/ramdisk.stock.cpio.lzma
fi

if [ ! -f /system/bin/mr.stock ]
then
	echo "Rename stock mr"
	${BUSYBOX} mv /system/bin/mr /system/bin/mr.stock
fi

echo "Copy mr wrapper script to system."
${BUSYBOX} cp /data/local/tmp/recovery/mr /system/bin/
${BUSYBOX} chmod 755 /system/bin/mr

if [ ! -f /system/bin/chargemon.stock ]
then
	echo "Rename stock chargemon"
	${BUSYBOX} mv /system/bin/chargemon /system/bin/chargemon.stock
fi

echo "Copy chargemon script to system."
${BUSYBOX} cp /data/local/tmp/recovery/chargemon /system/bin/
${BUSYBOX} chmod 755 /system/bin/chargemon

echo "Copy dualrecovery.sh to system."
${BUSYBOX} cp /data/local/tmp/recovery/dualrecovery.sh /system/bin/
${BUSYBOX} chmod 755 /system/bin/dualrecovery.sh

echo "Copy rickiller.sh to system."
${BUSYBOX} cp /data/local/tmp/recovery/rickiller.sh /system/bin/
${BUSYBOX} chmod 755 /system/bin/rickiller.sh

echo "Installing NDRUtils to system."
${BUSYBOX} cp /data/local/tmp/recovery/NDRUtils.apk /system/app/
${BUSYBOX} chmod 644 /system/app/NDRUtils.apk

ROMVER=$(/system/bin/getprop ro.build.id)
if [ "$ROMVER" = "14.2.A.0.290" -o "$ROMVER" = "14.2.A.1.136" -o "$ROMVER" = "14.2.A.1.114" ]; then
	echo "Copy disableric to system."
	${BUSYBOX} cp /data/local/tmp/recovery/disableric /system/xbin/
	${BUSYBOX} chmod 755 /system/xbin/disableric
fi

echo "Copy busybox to system."
${BUSYBOX} cp /data/local/tmp/recovery/busybox /system/xbin/
${BUSYBOX} chmod 755 /system/xbin/busybox

FOLDER1=/sdcard/clockworkmod/
FOLDER2=/sdcard1/clockworkmod/
FOLDER3=/cache/recovery/

echo "Speeding up backups."
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

echo ""
echo "============================================="
echo "DEVICE WILL NOW REBOOT!"
echo "============================================="
echo ""

reboot
