#!/bin/sh

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
	echo "=               XZDualRecovery               ="
	echo "=            Maintained by [NUT]             ="
	echo "=                                            ="
	echo "=      For many Sony Xperia devices!         ="
	echo "=                                            ="
	echo "=============================================="
	echo ""
	echo "          Run the installer with sudo if it fails to connect to your device!"
	echo ""
	echo "          Choose an installation option:"
	echo ""
	echo "          1/ Installation on device rooted with SuperSU"
	echo "          2/ Installation on device rooted with SuperUser"
	echo "          3/ Installation on an unrooted (Lollipop 5.0) ROM using rootkitXperia"
	echo ""
	echo "          Q/ Exit"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        1) clear; echo "Adjusting for SuperSU!"; SUPERAPP="supersu"; runinstall;;
	        2) clear; echo "Adjusting for SuperUser!"; SUPERAPP="superuser"; runinstall;;
	        3) clear; echo "Using rootkitXperia to attempt an installation."; SUPERAPP="unrooted"; runinstall;;
	        q|Q) clear; exit;;
	      	*) echo "$num is not a valid option"; sleep 3; clear; rootappmenu;
	esac
}

unrootedmenu() {
	echo ""
	echo "If your device booted to recovery and you see this menu, please reboot your device to system and press C."
	echo ""
	echo "You should have been told it is installing the recovery package, including a version."
	echo ""
	echo "If the unrooted installation failed, please press R once the device finished rebooting to retry!"
	echo ""
	echo "    R/ Retry installation on an unrooted ROM using rootkitXperia"
	echo "    C/ Continue installation"
	echo "    Q/ Exit"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        r|R) clear; echo "Retrying the rootkitXperia installation."; unrooted retry;;
	        c|C) clear; return 0;;
	        q|Q) clear; exit;;
	      	*) echo "$num is not a valid option"; sleep 3; clear; unrootedmenu;
	esac
}

unrooted() {

	if [ "$1" != "retry" ]; then

		echo "============================================="
		echo "Attempting to get root access for installation using rootkitXperia now."
		echo ""
		echo "NOTE: this only works on certain ROM/Kernel versions!"
		echo ""
		echo "If it fails, please check the development thread (Post #2) on XDA for more details."
		echo ""
		echo "******** REMEMBER THIS: ********"
		echo ""
		echo "XZDualRecovery does NOT install any superuser app!!"
		echo ""
		echo "You can use one of the recoveries to root your device."
		echo "============================================="

		echo "To continue, press enter..."

		read anykey

		echo ""
		echo "============================================="
		echo "Sending files"
		echo "============================================="

		./${ADBBINARY} push rootkitxperia/getroot /data/local/tmp/recovery/getroot
		./${ADBBINARY} shell "chmod 755 /data/local/tmp/recovery/getroot"

	fi

	echo ""
	echo "============================================="
	echo "Installing using rootkitXperia by cubeundcube"
	echo ""
	echo "Big thanks to anyone involved in the development:"
	echo ""
	echo "Keen Team, cubeundcube, AndroPlus and zxz0O0"
	echo "============================================="

	./${ADBBINARY} shell '/data/local/tmp/recovery/getroot "/data/local/tmp/recovery/install.sh unrooted"'

	sleep 15

	echo ""
	echo "============================================="
	echo "If your device now boots to recovery, reboot "
	echo "it to system to continue and allow this script"
	echo "to check and clean up. The script will continue"
	echo "once your device allows adb connections again."
	echo "============================================="
	echo ""

	./${ADBBINARY} kill-server
	./${ADBBINARY} start-server
	./${ADBBINARY} wait-for-device

	INSTALLTEST=$(./${ADBBINARY} shell '/system/bin/ls /system/bin/dualrecovery.sh' | grep "dualrecovery.sh" | wc -l)
#	if [ "$INSTALLTEST" != "1" ]; then

		unrootedmenu

#	fi

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
	echo "Device and firmware information:"
	echo "============================================="
	product_name=`./${ADBBINARY} shell "getprop ro.build.product"`
	echo "Device model is $product_name"
	firmware=`./${ADBBINARY} shell "getprop ro.build.id"`
	echo "Firmware is $firmware"
	echo ""
	echo "============================================="
	echo "Step2 : Sending the recovery files."
	echo "============================================="
	echo ""
	./${ADBBINARY} shell "mkdir /data/local/tmp/recovery"
	./${ADBBINARY} push ../tmp/dr.prop /data/local/tmp/recovery/dr.prop
	./${ADBBINARY} push ../system/bin/chargemon /data/local/tmp/recovery/chargemon
	./${ADBBINARY} push ../system/bin/mr /data/local/tmp/recovery/mr
	./${ADBBINARY} push ../system/.XZDualRecovery/xbin/dualrecovery.sh /data/local/tmp/recovery/dualrecovery.sh
	./${ADBBINARY} push ../tmp/NDRUtils.apk /data/local/tmp/recovery/NDRUtils.apk
	./${ADBBINARY} push ../system/.XZDualRecovery/xbin/rickiller.sh /data/local/tmp/recovery/rickiller.sh
	./${ADBBINARY} push ../tmp/byeselinux.ko /data/local/tmp/recovery/byeselinux.ko
	./${ADBBINARY} push byeselinux/byeselinux.sh /data/local/tmp/recovery/byeselinux.sh
	./${ADBBINARY} push ../tmp/wp_mod.ko /data/local/tmp/recovery/wp_mod.ko
	./${ADBBINARY} push byeselinux/sysrw.sh /data/local/tmp/recovery/sysrw.sh
	./${ADBBINARY} push ../tmp/modulecrcpatch /data/local/tmp/recovery/modulecrcpatch
	./${ADBBINARY} push ../system/.XZDualRecovery/xbin/busybox /data/local/tmp/recovery/busybox
	./${ADBBINARY} push ../system/.XZDualRecovery/xbin/recovery.twrp.cpio.lzma /data/local/tmp/recovery/recovery.twrp.cpio.lzma
#	./${ADBBINARY} push recovery.cwm.cpio.lzma /data/local/tmp/recovery/recovery.cwm.cpio.lzma
	./${ADBBINARY} push ../system/.XZDualRecovery/xbin/recovery.philz.cpio.lzma /data/local/tmp/recovery/recovery.philz.cpio.lzma
	if [ -f "../system/.XZDualRecovery/xbin/ramdisk.stock.cpio.lzma" ]; then
		./${ADBBINARY} push ../system/.XZDualRecovery/xbin/ramdisk.stock.cpio.lzma /data/local/tmp/recovery/ramdisk.stock.cpio.lzma
	fi
	./${ADBBINARY} push ../tmp/installrecovery.sh /data/local/tmp/recovery/install.sh
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
		echo "Press enter to continue AFTER granting root access."
		read blah
	fi

	if [ "$SUPERAPP" = "superuser" -o "$SUPERAPP" = "supersu" ]; then
		./${ADBBINARY} shell "/system/xbin/su -c /data/local/tmp/recovery/install.sh"
	fi

	if [ "$SUPERAPP" = "unrooted" ]; then

		unrooted

	fi

	./${ADBBINARY} wait-for-device
	./${ADBBINARY} shell "/system/bin/rm -rf /data/local/tmp/recovery"
	INSTALLTEST=$(./${ADBBINARY} shell '/system/bin/ls /system/bin/dualrecovery.sh' | grep "dualrecovery.sh" | wc -l)
	if [ "$INSTALLTEST" = "1" ]; then
		echo ""
		echo "============================================="
		echo "Installation finished. Enjoy the recoveries!"
		echo "============================================="
		echo ""
	else
		echo ""
		echo "============================================="
		echo "             Installation FAILED!"
		echo ""
		echo "Please copy and paste the contents of"
		echo "this window/screen to the DevDB thread."
		echo "============================================="
		echo ""
	fi
	./${ADBBINARY} kill-server
	exit 0

}

# Fire up the menu
while :
do
        rootappmenu
done
