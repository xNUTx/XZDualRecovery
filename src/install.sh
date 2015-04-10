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
	echo "=               XZDualRecovery               ="
	echo "=            Maintained by [NUT]             ="
	echo "=                                            ="
	echo "=      For many Sony Xperia devices!         ="
	echo "=                                            ="
	echo "=============================================="
	echo ""
	echo "          Choose an installation option:"
	echo ""
	echo "          1/ Installation on device rooted with SuperSU"
	echo "          2/ Installation on device rooted with SuperUser"
	echo "          3/ Attempt installation on an unrooted device"
	echo ""
	echo "          Q/ Exit"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        1) clear; echo "Adjusting for SuperSU!"; SUPERAPP="supersu"; runinstall;;
	        2) clear; echo "Adjusting for SuperUser!"; SUPERAPP="superuser"; runinstall;;
	        3) clear; echo "Using TowelRoot to attempt an installation."; SUPERAPP="unrooted"; runinstall;;
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
	./${ADBBINARY} push dr.prop /data/local/tmp/recovery/dr.prop
	./${ADBBINARY} push chargemon.sh /data/local/tmp/recovery/chargemon
	./${ADBBINARY} push mr.sh /data/local/tmp/recovery/mr
	./${ADBBINARY} push dualrecovery.sh /data/local/tmp/recovery/dualrecovery.sh
	./${ADBBINARY} push NDRUtils.apk /data/local/tmp/recovery/NDRUtils.apk
	./${ADBBINARY} push rickiller.sh /data/local/tmp/recovery/rickiller.sh
	./${ADBBINARY} push byeselinux/byeselinux.ko /data/local/tmp/recovery/byeselinux.ko
	./${ADBBINARY} push byeselinux/byeselinux.sh /data/local/tmp/recovery/byeselinux.sh
	./${ADBBINARY} push byeselinux/wp_mod.ko /data/local/tmp/recovery/wp_mod.ko
	./${ADBBINARY} push byeselinux/sysrw.sh /data/local/tmp/recovery/sysrw.sh
	./${ADBBINARY} push byeselinux/modulecrcpatch /data/local/tmp/recovery/modulecrcpatch
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

	if [ "$SUPERAPP" = "unrooted" ]; then

		echo "============================================="
		echo "Attempting to get root access for installation using TowelRoot now."
		echo ""
		echo "NOTE: this only works on certain ROM/Kernel versions!"
		echo ""
		echo "If it fails, please check the development thread (Post #2) on XDA for more details."
		echo "============================================="

		echo ""
		echo "============================================="
		echo "Sending files"
		echo "============================================="

		./${ADBBINARY} push easyroottool/zxz.sh /data/local/tmp/zxz.sh
		./${ADBBINARY} push easyroottool/towelzxperia /data/local/tmp/
		./${ADBBINARY} push easyroottool/libexploit.so /data/local/tmp/
		./${ADBBINARY} push easyroottool/writekmem /data/local/tmp/
		./${ADBBINARY} push easyroottool/findricaddr /data/local/tmp/
		./${ADBBINARY} shell "cp /data/local/tmp/recovery/busybox /data/local/tmp/"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/busybox"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/zxz.sh"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/towelzxperia"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/writekmem"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/findricaddr"

		echo "Copying kernel module..."
		./${ADBBINARY} push easyroottool/wp_mod.ko /data/local/tmp
		./${ADBBINARY} push easyroottool/kernelmodule_patch.sh /data/local/tmp
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/kernelmodule_patch.sh"
		./${ADBBINARY} push easyroottool/modulecrcpatch /data/local/tmp
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/modulecrcpatch"
		./${ADBBINARY} shell "/data/local/tmp/kernelmodule_patch.sh"

		echo ""
		echo "============================================="
		echo "Installing using zxz0O0's towelzxperia (using geohot's towelroot library)"
		echo "============================================="

		./${ADBBINARY} shell "/data/local/tmp/towelzxperia /data/local/tmp/recovery/install.sh unrooted"

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

	./${ADBBINARY} wait-for-device
	./${ADBBINARY} shell "/system/xbin/busybox rm -rf /data/local/tmp/recovery"
	if [ "`./${ADBBINARY} shell '/system/xbin/busybox ls -1 /system/bin/dualrecovery.sh' | tr -d '\n\r\t'`" = "/system/bin/dualrecovery.sh" ]; then
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
