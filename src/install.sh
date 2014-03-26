#!/usr/bin/sudo /bin/sh

SUPERAPP="superuser"
ADBBINARY="adb.linux"
OS=$(uname)

chmod +x files/adb.linux
chmod +x files/adb.mac

if [ "$OS" = "Linux" ]; then
	ADBBINARY="adb.linux"
fi

if [ "$OS" = "Darwin" ]; then
	ADBBINARY="adb.mac"
fi

rootappmenu() {
	clear
	echo "=============================================="
	echo "=                                            ="
	echo "=              XZDualRecovery                ="
	echo "=           Maintained by [NUT]              ="
	echo "=                                            ="
	echo "=  For Xperia Z, ZL, Z1, Z Ultra & Tablet Z  ="
	echo "=                                            ="
	echo "=============================================="
	echo ""
	echo "          Choose an installation option:"
	echo ""
	echo "          1/ Installation on device rooted with SuperSU"
	echo "          2/ Installation on device rooted with SuperUser"
	echo "          3/ Attempt installation on unrooted device"
	echo ""
	echo "          Q/ Exit"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        1) clear; echo "Ajusting for SuperSU!"; SUPERAPP="supersu"; runinstall;;
	        2) clear; echo "Ajusting for SuperUser!"; SUPERAPP="superuser"; runinstall;;
	        3) clear; echo "Will attempt to get root to install!"; SUPERAPP="getroot"; runinstall;;
	        q|Q) clear; exit;;
	      	*) echo "$num is not a valid option"; sleep 3; clear; rootappmenu;
	esac
}

runinstall() {
	cd files
	./${ADBBINARY} kill-server
	./${ADBBINARY} start-server
	echo ""
	echo "============================================="
	echo "Step1 : Waiting for Device."
	echo "============================================="
	echo ""
	./${ADBBINARY} wait-for-device
	echo "Succes"
	echo ""
	echo "============================================="
	echo "Step2 : Sending the recovery files."
	echo "============================================="
	echo ""
	./${ADBBINARY} shell "mkdir /data/local/tmp/recovery"
	./${ADBBINARY} push dr.prop /data/local/tmp/recovery/dr.prop
	if [ "$SUPERAPP" = "getroot" ]; then
		./${ADBBINARY} push getroot /data/local/tmp/recovery/getroot
	fi
	./${ADBBINARY} push chargemon.sh /data/local/tmp/recovery/chargemon
	./${ADBBINARY} push mr.sh /data/local/tmp/recovery/mr
	./${ADBBINARY} push dualrecovery.sh /data/local/tmp/recovery/dualrecovery.sh
	./${ADBBINARY} push NDRUtils.apk /data/local/tmp/recovery/NDRUtils.apk
	./${ADBBINARY} push rickiller.sh /data/local/tmp/recovery/rickiller.sh
	./${ADBBINARY} push disableric /data/local/tmp/recovery/disableric
	./${ADBBINARY} push busybox /data/local/tmp/recovery/busybox
	./${ADBBINARY} push recovery.twrp.cpio.lzma /data/local/tmp/recovery/recovery.twrp.cpio.lzma
	./${ADBBINARY} push recovery.cwm.cpio.lzma /data/local/tmp/recovery/recovery.cwm.cpio.lzma
	./${ADBBINARY} push recovery.philz.cpio.lzma /data/local/tmp/recovery/recovery.philz.cpio.lzma
	if [ -f "ramdisk.stock.cpio.lzma" ]; then
		./${ADBBINARY} push ramdisk.stock.cpio.lzma /data/local/tmp/recovery/ramdisk.stock.cpio.lzma
	fi
	./${ADBBINARY} push installrecovery.sh /data/local/tmp/recovery/install.sh
	echo ""
	echo "============================================="
	echo "Step3 : Setup of dual recovery."
	echo "============================================="
	echo ""
	./${ADBBINARY} shell "chmod 755 /data/local/tmp/recovery/install.sh"
	./${ADBBINARY} shell "chmod 755 /data/local/tmp/recovery/busybox"

	if [ "$SUPERAPP" = "supersu" ]; then
		echo "Look at your device and grant supersu access!"
		./${ADBBINARY} shell "su -c /system/bin/ls -la /data/local/tmp/recovery/busybox"
		echo "Press any key to continue AFTER granting root access."
		read blah
	fi

	if [ "$SUPERAPP" = "superuser" -o "$SUPERAPP" = "supersu" ]; then
		./${ADBBINARY} shell "/system/xbin/su -c /data/local/tmp/recovery/install.sh"
	fi

	if [ "$SUPERAPP" = "getroot" ]; then
		echo "============================================="
		echo "Attempting to get root access for installation using rootkitXperia now."
		echo ""
		echo "NOTE: this only works on certain ROM/Kernel versions!"
		echo ""
		echo "If it fails, please check the development thread on XDA for more details."
		echo "============================================="

		./${ADBBINARY} shell "chmod 755 /data/local/tmp/recovery/getroot"
		./${ADBBINARY} shell "/data/local/tmp/recovery/getroot /data/local/tmp/recovery/install.sh"

		echo "============================================="
		echo ""
		echo "REMEMBER THIS:"
		echo ""
		echo "XZDualRecovery does NOT install any superuser app!!"
		echo ""
		echo "You can use one of the recoveries to root your device."
		echo ""
		echo "============================================="
	fi

	echo "Waiting for your device to reconnect."
	echo "After entering CWM for the first time, reboot to system to complete this installer if you want it to clean up after itself."
	./${ADBBINARY} wait-for-device
	./${ADBBINARY} shell "rm -rf /data/local/tmp/recovery"
	./${ADBBINARY} kill-server
	echo ""
	echo "============================================="
	echo "Installation finished. Enjoy the recoveries!"
	echo "============================================="
	echo ""
	exit 0
}

# Fire up the menu
while :
do
        rootappmenu
done
