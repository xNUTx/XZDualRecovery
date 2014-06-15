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
	        3) clear; SUPERAPP="getroot"; unrootedrootmenu;;
	        q|Q) clear; exit;;
	      	*) echo "$num is not a valid option"; sleep 3; clear; rootappmenu;
	esac
}

unrootedrootmenu() {

	echo "=============================================="
	echo "=                                            ="
	echo "=               XZDualRecovery               ="
	echo "=            Maintained by [NUT]             ="
	echo "=                                            ="
	echo "=      For many Sony Xperia devices!         ="
	echo "=                                            ="
	echo "=============================================="
	echo ""
	echo "          Choose the root method to use:"
	echo ""
	echo "          1/ Use the vold exploit developed by Sacha and GranPC"
	echo "          2/ Use RootkitXperia by cubeundcube"
	echo ""
	echo "          B/ Back to main menu"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        1) clear; echo "Will attempt the vold method by Sacha and GranPC!"; SUPERAPP="vold"; runinstall;;
	        2) clear; echo "Will attempt the getroot method by Cubeundcube!"; SUPERAPP="getroot"; runinstall;;
	        b|B) clear; rootappmenu;;
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

	if [ "$SUPERAPP" = "vold" ]; then

		echo "============================================="
		echo "Attempting to get root access for installation using the vold exploit now."
		echo ""
		echo "NOTE: this only works on certain ROM/Kernel versions!"
		echo ""
		echo "If it fails, please check the development thread (Post #2) on XDA for more details."
		echo "============================================="

		if [[ -n $(./${ADBBINARY} shell 'pm list packages -f' | grep com.peniscorp.bobsgamecontrols) ]]; then
  		echo "Exploit app already installed. Continuing."
		else
  		echo "Installing exploit app."
  		./${ADBBINARY} install sacha-granpc/exploit/exploit.apk
		fi

		# Now let us copy the scripts
		echo "Copying files.."
		./${ADBBINARY} push sacha-granpc/scripts/ /data/local/tmp/recovery/
		./${ADBBINARY} shell chmod 777 /data/local/tmp/recovery/
		./${ADBBINARY} shell /data/local/tmp/recovery/vdcCreate
		./${ADBBINARY} shell /data/local/tmp/recovery/startService

		echo "Test VDC #1:"
		./${ADBBINARY} shell 'if [ -s /data/app-lib/ServiceMenu/libservicemenu.so ]; then echo "Success"; else echo "Failure" && exit; fi'

		echo -e "\n\n --- Attention ---\nPlease 'crash' the Service Menu app that pops up."
		echo "For example: Service Info -> Configuration."

		# Will only continue if SELinux is disabled
		while [[ `./${ADBBINARY} shell getenforce` != "Permissive" ]]; do sleep 2; done
		echo "Congratulations, SELinux is dead. Continuing.."
		./${ADBBINARY} shell 'vdc asec mount ../../data/local/tmp/recovery/vlib none 2000'
		./${ADBBINARY} shell /data/local/tmp/recovery/startService

		echo "Test VDC #2: "
		./${ADBBINARY} shell 'if [ -s /data/local/tmp/recovery/vlib/liblogwrap.so ]; then echo "Success"; else echo "Failure" && exit; fi'

		echo -e "\n\n --- Attention ---\nPlease 'crash' the Service Menu app that pops up."
		echo "For example: Service Info -> Configuration."
		
		while [[ `adb shell 'ls /data/local/tmp/xzdrinstalled'` != "/data/local/tmp/xzdrinstalled" ]]; do sleep 2; done
		./${ADBBINARY} shell "rm /data/local/tmp/xzdrinstalled"
		echo "Congratulations, it worked! Your device will now reboot!"
		
	fi

	if [ "$SUPERAPP" = "getroot" ]; then

		echo "============================================="
		echo "Attempting to get root access for installation using rootkitXperia now."
		echo ""
		echo "NOTE: this only works on certain ROM/Kernel versions!"
		echo ""
		echo "If it fails, please check the development thread (Post #2) on XDA for more details."
		echo "============================================="

		./${ADBBINARY} shell "chmod 755 /data/local/tmp/recovery/getroot"
		./${ADBBINARY} shell "/data/local/tmp/recovery/getroot /data/local/tmp/recovery/install.sh"

	fi

	if [ "$SUPERAPP" = "getroot" -o "$SUPERAPP" = "vold" ]; then

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
