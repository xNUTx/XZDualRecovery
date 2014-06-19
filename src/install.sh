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

		if [ ! -f "easyroottool/tr_signed.apk" ]; then
			echo "Will download towelroot and patch it if needed."
			if [ ! -f "easyroottool/tr.apk" ]; then
				curl http://towelroot.com/tr.apk -o easyroottool/tr.apk
			fi
			echo "============================================="
			echo "Patching tr.apk and creating tr_signed.apk"
			echo "============================================="
			chmod 755 ./easyroottool/bspatch
			./easyroottool/bspatch easyroottool/tr.apk easyroottool/tr_signed.apk easyroottool/tr.apk.patch
			if [ ! -f "easyroottool/tr_signed.apk" ]; then
				echo "Error patching tr.apk. Aborting..."
				echo "Press any key to go back to the menu."
				return 127
			fi
			tr_md5=`md5sum easyroottool/tr_signed.apk`
			if [ "$tr_md5" != "d83363748cb1dced97cc630419f8d587  easyroottool/tr_signed.apk" ]; then
				echo "Error patching tr.apk. MD5 does not match. Aborting..."
				echo "Current MD5 is: $tr_md5"
				echo "Press any key to go back to the menu."
				rm easyroottool/tr_signed.apk
				return 127
			fi
		fi
		echo ""

		if [ "$OS" = "Linux" ]; then
			echo "It looks like you are running Linux"
			echo "Please make sure ia32-libs is installed if you get any errors"
			echo ""
		fi

		echo ""
		echo "============================================="
		echo "Getting ro.build.product"
		echo "============================================="
		product_name=`./${ADBBINARY} shell "getprop ro.build.product"`
		echo "Device model is $product_name"

		echo ""
		echo "============================================="
		echo "Sending files"
		echo "============================================="

		zxzFile="zxz.sh"

		if [ "$product_name" = "D6502 " ] || [ "$product_name" = "D6503 " ] || [ "$product_name" = "D6506 " ] || [ "$product_name" = "D6543 " ] || [ "$product_name" = "SGP511 " ] || [ "$product_name" = "SGP512 " ] || [ "$product_name" = "SGP521 " ]; then
			zxzFile="zxz_z2.sh"
			echo "Using Z2 files..."
		fi

		./${ADBBINARY} push easyroottool/$zxzFile /data/local/tmp/zxz.sh
		./${ADBBINARY} push easyroottool/writekmem /data/local/tmp/
		./${ADBBINARY} push easyroottool/findricaddr /data/local/tmp/
		./${ADBBINARY} shell "cp /data/local/tmp/recovery/busybox /data/local/tmp/"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/busybox"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/zxz.sh"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/writekmem"
		./${ADBBINARY} shell "chmod 777 /data/local/tmp/findricaddr"

		echo ""
		echo "============================================="
		echo "Loading modified towelroot (by geohot)"
		echo "============================================="

		./${ADBBINARY} uninstall com.geohot.towelroot
		./${ADBBINARY} install easyroottool/tr_signed.apk

		./${ADBBINARY} shell "am start -n com.geohot.towelroot/.TowelRoot" &> /dev/null
		echo "============================================="
		echo "Check your phone and click \"make it ra1n\""
		echo ""
		echo "ATTENTION: Press any key when the phone is DONE rebooting"
		read tmpvar
		./${ADBBINARY} wait-for-device
		./${ADBBINARY} uninstall com.geohot.towelroot
		./${ADBBINARY} shell "su -c /data/local/tmp/recovery/install.sh"
		echo "============================================="

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
	./${ADBBINARY} shell "rm -rf /data/local/tmp/*"
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
