#! /bin/bash

MAJOR=`cat $WORKDIR/scripts/version`
MINOR=`cat $WORKDIR/scripts/minor`
REVISION=`cat $WORKDIR/scripts/revision`
RELEASE=`cat $WORKDIR/scripts/release`

source scripts/recovery.sh
source scripts/version.sh
source scripts/upload.sh
source scripts/build.sh

dualrecovery_action_menu_opt() {
	clear
	echo ""
	echo ""
	echo " Xperia DualRecovery Action Menu"
	echo ""
	echo "          Current device: ${LABEL} (${CODENAME})"
	echo "          Current version: ${MAJOR}.${MINOR}.${REVISION}"
	echo "          Current type: ${RELEASE}"
	echo ""
	echo "          B/ Build menu"
	echo ""
	echo "          R/ Recovery menu"
	echo ""
        echo "          V/ Version Menu"
        echo ""
	echo "          U/ Upload Files"
	echo ""
        echo "          D/ Back to Device menu"
	echo "          Q/ Quit"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        b|B) clear; buildparts_menu_opt;;
	        r|R) clear; recovery_menu_opt;;
                v|V) clear; version_menu_opt;;
	        u|U) clear; uploadfiles; dualrecovery_action_menu_opt;;
		d|D) clear; dualrecovery_menu_opt;;
        	q|Q) clear; exit;;
        	*) echo "$num is not a valid option"; sleep 3; clear; dualrecovery_action_menu_opt;
	esac
}

buildparts_menu_opt() {
        clear
        echo ""
        echo ""
        echo " Xperia DualRecovery Build Menu"
        echo ""
	echo "          Current device: ${LABEL} (${CODENAME})"
	echo "          Current version: ${MAJOR}.${MINOR}.${REVISION}"
	echo "          Current type: ${RELEASE}"
        echo ""
        echo "          1/ Build TWRP cpio"
        echo "          2/ Build PhilZ cpio"
        echo "          3/ Build CWM cpio"
        echo ""
	if [ -d "$WORKDIR/ramdisks/${DRPATH}/ramdisk.stock" ]; then
        	echo "          4/ Pack stock ramdisk"
        	echo ""
        fi
        echo "          5/ Create flashable zip"
        echo "          6/ Create installer"
        echo ""
        echo "          C/ Cleanup /tmp and /out"
        echo "          S/ Copy package base to /tmp"
        echo "          A/ Do all of the above"
        echo ""
	echo "          B/ Back to Action menu"
        echo "          Q/ Quit"
        echo ""
        echo "    Enter option:"
        echo ""
        read num
        case $num in
                1) clear; maketwrp; buildparts_menu_opt;;
                2) clear; makephilz; buildparts_menu_opt;;
                3) clear; makecwm; buildparts_menu_opt;;
                4) clear; makestock; buildparts_menu_opt;;
                5) clear; packflashable; buildparts_menu_opt;;
                6) clear; packinstaller; buildparts_menu_opt;;
                c|C) clear; cleanuptmp; cleanupout; buildparts_menu_opt;;
                s|S) clear; copyxzsource; buildparts_menu_opt;;
                a|A) clear; doall; buildparts_menu_opt;;
                b|B) clear; dualrecovery_action_menu_opt;;
                q|Q) clear; exit;;
                *) echo "$num is not a valid option"; sleep 3; clear; buildparts_menu_opt;
        esac
}

version_menu_opt() {
	clear
	echo ""
	echo ""
	echo " Xperia DualRecovery Version Menu"
	echo ""
	echo "          Current device: ${LABEL} (${CODENAME})"
	echo "          Current version: ${MAJOR}.${MINOR}.${REVISION}"
	echo "          Current type: ${RELEASE}"
	echo ""
	echo "          1/ Increment version"
	echo "          2/ Increment minor"
	echo "          3/ Increment revision"
	echo "          4/ Toggle release type"
	echo ""
	echo "          B/ Back to Action menu"
	echo "          Q/ Quit"
	echo ""
	echo "    Enter option now:"
	echo ""
	read num
	case $num in
	        1) clear; incrversion; version_menu_opt;;
	        2) clear; incrminor; version_menu_opt;;
	        3) clear; incrrevision; version_menu_opt;;
	        4) clear; togglerelease; version_menu_opt;;
        	b|B) clear; dualrecovery_action_menu_opt;;
        	q|Q) clear; exit;;
        	*) echo "$num is not a valid option"; sleep 3; clear; version_menu_opt;
	esac
}

recovery_menu_opt() {
	clear
	echo ""
	echo ""
	echo " Xperia DualRecovery Recovery Menu"
	echo ""
	echo "          Current device: ${LABEL} (${CODENAME})"
	echo ""
	echo "          1/ Get latest built CWM Recovery"
	echo "          2/ Get latest built PhilZ Touch Recovery"
	echo "          3/ Get latest built TWRP recovery"
	echo "          4/ Apply private patches"
	echo ""
	echo "          B/ Back to Action menu"
	echo "          Q/ Quit"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        1) clear; copycwm; recovery_menu_opt;;
	        2) clear; copyphilz; recovery_menu_opt;;
	        3) clear; copytwrp; recovery_menu_opt;;
	        4) clear; recoverypatcher; recovery_menu_opt;;
        	b|B) clear; dualrecovery_action_menu_opt;;
        	q|Q) clear; exit;;
        	*) echo "$num is not a valid option"; sleep 3; clear; recovery_menu_opt;
	esac
}
