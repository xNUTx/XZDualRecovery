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

MAJOR=`cat $WORKDIR/scripts/version`
MINOR=`cat $WORKDIR/scripts/minor`
REVISION=`cat $WORKDIR/scripts/revision`
RELEASE=`cat $WORKDIR/scripts/release`

dualrecovery_menu_opt() {
	clear
	echo ""
	echo ""
	echo " Xperia DualRecovery Device Menu"
	echo ""
        echo "          Current version: ${MAJOR}.${MINOR}.${REVISION}"
        echo "          Current type: ${RELEASE}"
	echo ""
	echo "          1 / Xperia Z		(x)"
	echo "          2 / Xperia Z1		(x)"
	echo "          3 / Xperia ZU		(x)"
	echo "          4 / Xperia ZL		(x)"
	echo "          5 / Xperia TabZ	(x)"
	echo "          6 / Xperia Z1 Compact	(x)"
	echo "          7 / Xperia ZR		(x)"
	echo "          8 / Xperia J"
	echo "          9 / Xperia P"
	echo "          10/ Xperia T/TL/TX/V	(x)"
	echo "          11/ Xperia SP		(x)"
	echo "          12/ Xperia S		(x)"
	echo "          13/ Xperia Z2		(x)"
	echo ""
	if [ -n "$PROJECTS" ]; then
		echo "          B/ Back to Projects menu"
		echo ""
	fi
	echo "          I / Increment Revision"
	echo ""
	echo "          V/ Version Menu"
	echo ""
	echo "          U / Upload Available Builds"
	echo ""
	echo "          A / Rebuild all (x) marked devices"
	echo ""
	echo "          Q / Quit"
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
	        12) clear; builds;;
	        13) clear; buildz2;;
		i|I) clear; incrrev;;
		v|V) clear; version_menu_opt;;
		u|U) clear; uploadallfiles;;
		a|A) clear; buildallxed;;
        	b|B) clear; projects_menu_opt;;
        	q|Q) clear; exit;;
        	*) echo "$num is not a valid option"; sleep 3; clear; dualrecovery_menu_opt;
	esac
}

loadsources() {
	source $WORKDIR/scripts/recovery.sh
	source $WORKDIR/scripts/kernel.sh
	source $WORKDIR/scripts/version.sh
	source $WORKDIR/scripts/upload.sh
	source $WORKDIR/scripts/build.sh
}

buildallxed() {
	echo "Rebuild all? (y/n)"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		loadsources
		echo "Include kernel versions? (y/n)"
		read answer

		buildxz auto
		doall
		if [ "$answer" = "y" -o "$answer" = "Y" ]; then
			doallkernel
		fi

		buildz1 auto
		doall
		if [ "$answer" = "y" -o "$answer" = "Y" ]; then
			doallkernel
		fi

		buildzu auto
		doall
		if [ "$answer" = "y" -o "$answer" = "Y" ]; then
			doallkernel
		fi

		buildzl auto
		doall

		buildtabz auto
		doall

		buildz1c auto
		doall
		if [ "$answer" = "y" -o "$answer" = "Y" ]; then
			doallkernel
		fi

		buildzr auto
		doall

		buildt auto
		doall

		buildsp auto
		doall

		builds auto
		doall

		buildz2 auto
		doall
	fi
	uploadallfiles auto
}

incrrev() {
	echo "Increment revision? (y/n)"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		loadsources
		incrrevision
	fi
}

uploadallfiles() {
	if [ "$*" != "auto" ]; then
		loadsources
	fi
	echo "Upload files now? (y/n)"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		uploadfiles all
	fi
}

buildxz() {
        cd $WORKDIR
	LABEL="XZ"
	DRPATH="xz"
	CODENAME="yuga"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="yes"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildzr() {
        cd $WORKDIR
	LABEL="ZR"
	DRPATH="zr"
	CODENAME="dogo"
	REPO="cm11.0"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildz1() {
        cd $WORKDIR
	LABEL="Z1"
	DRPATH="z1"
	CODENAME="honami"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x00000000"
	RAMDISKOFFSET="0x02000000"
	TAGS="yes"
	TAGSOFFSET="0x01E00000"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="yes"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildzu() {
        cd $WORKDIR
	LABEL="ZU"
	DRPATH="zu"
	CODENAME="togari"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="yes"
	TAGSOFFSET="0x01E00000"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildtabz() {
        cd $WORKDIR
	LABEL="TabZ"
	DRPATH="tabz"
	CODENAME="pollux"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildz1c() {
        cd $WORKDIR
	LABEL="Z1C"
	DRPATH="z1c"
	CODENAME="amami"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="yes"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildj() {
        cd $WORKDIR
	LABEL="XJ"
	DRPATH="xj"
	CODENAME="jlo"
	REPO="cm11.0"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildp() {
        cd $WORKDIR
	LABEL="XP"
	DRPATH="xp"
	CODENAME="nypon"
	REPO="cm11.0"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildt() {
        cd $WORKDIR
	LABEL="XT"
	DRPATH="xt"
	CODENAME="mint"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="yes"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildsp() {
        cd $WORKDIR
	LABEL="XSP"
	DRPATH="xsp"
	CODENAME="huashan"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

builds() {
        cd $WORKDIR
	LABEL="XS"
	DRPATH="xs"
	CODENAME="nozomi"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x80200000"
	RAMDISKOFFSET="0x02000000"
	TAGS="no"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

buildz2() {
        cd $WORKDIR
	LABEL="Z2"
	DRPATH="z2"
	CODENAME="sirius"
	REPO="cm11.0"
	BUILDPHILZ="yes"
	BASE="0x00000000"
	RAMDISKOFFSET="0x02000000"
	TAGS="yes"
	TAGSOFFSET="0x01E00000"
	PAGESIZE="2048"
	KERNEL="Kernel"
	PACKRAMDISK="yes"
	PACKKERNELRAMDISK="no"
	if [ "$*" != "auto" ]; then
		source scripts/buildmenu.sh
		dualrecovery_action_menu_opt
	fi
}

# Fire up the menu
while :
do
        dualrecovery_menu_opt
done
