#!/usr/bin/sudo bash

PROJECT="dualrecovery"

if [ "$TOPDIR" = "" ]; then
        WORKDIR=`pwd`
else
        WORKDIR="$TOPDIR/$PROJECT"
fi

cd $WORKDIR

if [ ! -d "$WORKDIR/out" ]; then
	mkdir $WORKDIR/out
fi
if [ ! -d "$WORKDIR/tmp" ]; then
	mkdir $WORKDIR/tmp
fi

dualrecovery_menu_opt() {
	clear
	echo ""
	echo ""
	echo " Xperia DualRecovery Device Menu"
	echo ""
	echo "          1 / Xperia Z"
	echo "          2 / Xperia Z1"
	echo "          3 / Xperia ZU"
	echo "          4 / Xperia ZL"
	echo "          5 / Xperia TabZ"
	echo "          6 / Xperia Z1 Compact"
	echo "          7 / Xperia ZR"
	echo "          8 / Xperia J"
	echo "          9 / Xperia P"
	echo "          10/ Xperia T/TL/TX/V"
	echo "          11/ Xperia SP"
	echo ""
	if [ -n "$PROJECTS" ]; then
		echo "          B/ Back to Projects menu"
		echo ""
	fi
	echo "          Q/ Quit"
	echo ""
	echo "    Enter option:"
	echo ""
	read num
	case $num in
	        1) clear; buildxz;;
	        2) clear; buildz1;;
	        3) clear; buildzu;;
	        4) clear; buildzl;;
	        5) clear; buildtabz;;
	        6) clear; buildz1c;;
	        7) clear; buildzr;;
	        8) clear; buildj;;
	        9) clear; buildp;;
	        10) clear; buildt;;
	        11) clear; buildsp;;
        	b|B) clear; projects_menu_opt;;
        	q|Q) clear; exit;;
        	*) echo "$num is not a valid option"; sleep 3; clear; dualrecovery_menu_opt;
	esac
}

buildxz() {
        cd $WORKDIR
	LABEL="XZ"
	DRPATH="xz"
	CODENAME="yuga"
	REPO="cm10.2"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildzr() {
        cd $WORKDIR
	LABEL="ZR"
	DRPATH="zr"
	CODENAME="dogo"
	REPO="cm10.2"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildz1() {
        cd $WORKDIR
	LABEL="Z1"
	DRPATH="z1"
	CODENAME="honami"
	REPO="cm10.2"
	BASE="0x00000000"
	RAMDISKOFFSET="0x02000000"
	TAGS="yes"
	TAGSOFFSET="0x01E00000"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildzu() {
        cd $WORKDIR
	LABEL="ZU"
	DRPATH="zu"
	CODENAME="togari"
	REPO="cm10.2"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="yes"
	TAGSOFFSET="0x01E00000"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildzl() {
        cd $WORKDIR
	LABEL="ZL"
	DRPATH="zl"
	CODENAME="odin"
	REPO="cm10.2"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildtabz() {
        cd $WORKDIR
	LABEL="TabZ"
	DRPATH="tabz"
	CODENAME="pollux"
	REPO="cm10.2"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildz1c() {
        cd $WORKDIR
	LABEL="Z1C"
	DRPATH="z1c"
	CODENAME="amami"
	REPO="cm10.2"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildj() {
        cd $WORKDIR
	LABEL="XJ"
	DRPATH="xj"
	CODENAME="jlo"
	REPO="jellybean"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildp() {
        cd $WORKDIR
	LABEL="XP"
	DRPATH="xp"
	CODENAME="nypon"
	REPO="jellybean"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildt() {
        cd $WORKDIR
	LABEL="XT"
	DRPATH="xt"
	CODENAME="mint"
	REPO="cm10.1"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

buildsp() {
        cd $WORKDIR
	LABEL="XSP"
	DRPATH="xsp"
	CODENAME="huashan"
	REPO="cm10.1"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
        source scripts/buildmenu.sh
	dualrecovery_action_menu_opt
}

# Fire up the menu
while :
do
        dualrecovery_menu_opt
done
