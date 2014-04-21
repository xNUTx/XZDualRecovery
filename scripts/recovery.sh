#!/bin/bash

recoverypatcher() {
        cd $WORKDIR
        patchtwrp
        patchphilz
        patchcwm
	if [ "$1" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}

patchtwrp() {
	cp -vfr $WORKDIR/patches/all/twrp/* $WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp/
	cp -vfr $WORKDIR/patches/${DRPATH}/twrp/* $WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp/
}

patchcwm() {
	cp -vfr $WORKDIR/patches/all/cwm/* $WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm/
	cp -vfr $WORKDIR/patches/${DRPATH}/cwm/* $WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm/
}

patchphilz() {
	cp -vfr $WORKDIR/patches/all/philz/* $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
	cp -vfr $WORKDIR/patches/${DRPATH}/philz/* $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
}

# TWRP
copytwrp() {
	echo "Refresing TWRP source"
	if [ -d "$WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp" ]; then
		rm -rf $WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp/*
	else
		mkdir $WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp
	fi
	if [ "$1" != "auto" ]; then
		echo "Want to sync and build the latest TWRP version from GitHub? (y/n)"
		read answer
		if [ "$answer" = "y" -o "$answer" = "Y" ]; then
			compiletwrp
		fi
	fi
	cp -fr $WORKDIR/src/cyanogen/$REPO/twrp/android/system/out/target/product/${CODENAME}/ramdisk-recovery.cpio $WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp/
	cd $WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp/
	echo "unpacking source package"
	cpio -i -u < ramdisk-recovery.cpio
	rm -f ramdisk-recovery.cpio
	cd $WORKDIR
	if [ "$1" = "auto" ]; then
		sleep 2
	else
		echo "Press enter to return to the recovery menu!"
	        read
	fi
}

maketwrp() {
	echo "creating new TWRP recovery archive..."
	if [ -d "$WORKDIR/tmp/ramdisk.twrp" ]; then
		rm -rf $WORKDIR/tmp/ramdisk.twrp
	fi
	if [ -f "$WORKDIR/tmp/recovery.twrp.cpio.lzma" ]; then
		rm -f $WORKDIR/tmp/recovery.twrp.cpio.lzma
	fi
	echo "copying source package"
	cp -fr $WORKDIR/ramdisks/${DRPATH}/ramdisk.twrp $WORKDIR/tmp/
	cd $WORKDIR/tmp/ramdisk.twrp
	echo "packing destination package"
	find . | cpio --create --format='newc' > $WORKDIR/tmp/recovery.twrp.cpio
	if [ "$1" = "yes" ]; then
		lzma -e -4 $WORKDIR/tmp/recovery.twrp.cpio
	fi
	cd $WORKDIR
	if [ "$2" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}

# CWM
copycwm() {
	echo "Refresing CWM source"
	if [ -d "$WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm" ]; then
		rm -rf $WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm/*
	else
		mkdir $WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm/
	fi
	if [ "$1" != "auto" ]; then
		echo "Want to sync and build the latest CWM version from GitHub? (y/n)"
		read answer
		if [ "$answer" = "y" -o "$answer" = "Y" ]; then
			compilecwm
		fi
	fi
	cp -fr $WORKDIR/src/cyanogen/$REPO/cwm/android/system/out/target/product/${CODENAME}/ramdisk-recovery.cpio $WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm/
	cd $WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm/
	echo "unpacking source package"
	cpio -i -u < ramdisk-recovery.cpio
	rm -f ramdisk-recovery.cpio
	cd $WORKDIR
	if [ "$1" = "auto" ]; then
		sleep 2
	else
		echo "Press enter to return to the recovery menu!"
	        read
	fi
}

makecwm() {
	echo "creating new CWM recovery archive..."
	if [ -d "$WORKDIR/tmp/ramdisk.cwm" ]; then
		rm -rf $WORKDIR/tmp/ramdisk.cwm
	fi
	if [ -f "$WORKDIR/tmp/recovery.cwm.cpio.lzma" ]; then
		rm -f $WORKDIR/tmp/recovery.cwm.cpio.lzma
	fi
	echo "copying source package"
	cp -fr $WORKDIR/ramdisks/${DRPATH}/ramdisk.cwm $WORKDIR/tmp/
	cd $WORKDIR/tmp/ramdisk.cwm
	echo "packing destination package"
	find . | cpio --create --format='newc' > $WORKDIR/tmp/recovery.cwm.cpio
	if [ "$1" = "yes" ]; then
		lzma -e -4 $WORKDIR/tmp/recovery.cwm.cpio
	fi
	cd $WORKDIR
	if [ "$2" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}

# PhilZ Touch Recovery CWM
copyphilz() {
	if [ "$BUILDPHILZ" = "yes" ]; then
		echo "Refresing PhilZ source"
		if [ -d "$WORKDIR/ramdisks/${DRPATH}/ramdisk.philz" ]; then
			rm -rf $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/*
		else
		mkdir $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
		fi
		if [ "$1" != "auto" ]; then
			echo "Want to sync and build the latest PhilZ version from GitHub? (y/n)"
			read answer
			if [ "$answer" = "y" -o "$answer" = "Y" ]; then
				compilephilz
			fi
		fi
		cp -fr $WORKDIR/src/cyanogen/$REPO/philz/android/system/out/target/product/${CODENAME}/ramdisk-recovery.cpio $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
		cd $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
		echo "unpacking source package"
		cpio -i -u < ramdisk-recovery.cpio
		rm -f ramdisk-recovery.cpio
		cd $WORKDIR
		if [ "$1" = "auto" ]; then
			sleep 2
		else
			echo "Press enter to return to the recovery menu!"
		        read
		fi
	else
		echo "Refreshing PhilZ source"
		if [ -d "$WORKDIR/ramdisks/${DRPATH}/ramdisk.philz" ]; then
			rm -rf $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/*
		else
			mkdir $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
		fi
		cp -fr $WORKDIR/src/${DRPATH}/ramdisk-philz.cpio $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
		cd $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz/
		echo "unpacking source package"
		cpio -i -u < ramdisk-philz.cpio
		rm -f ramdisk-philz.cpio
		cd $WORKDIR
		if [ "$1" = "auto" ]; then
			sleep 2
		else
			echo "Press enter to return to the recovery menu!"
		        read
		fi
	fi
}

makephilz() {
	echo "creating new PhilZ recovery archive..."
	if [ -d "$WORKDIR/tmp/ramdisk.philz" ]; then
		rm -rf $WORKDIR/tmp/ramdisk.philz
	fi
	if [ -f "$WORKDIR/tmp/recovery.philz.cpio.lzma" ]; then
		rm -f $WORKDIR/tmp/recovery.philz.cpio.lzma
	fi
	echo "copying source package"
	cp -fr $WORKDIR/ramdisks/${DRPATH}/ramdisk.philz $WORKDIR/tmp/
	cd $WORKDIR/tmp/ramdisk.philz/
	echo "packing destination package"
	find . | cpio --create --format='newc' > $WORKDIR/tmp/recovery.philz.cpio
	if [ "$1" = "yes" ]; then
		lzma -e -4 $WORKDIR/tmp/recovery.philz.cpio
	fi
	cd $WORKDIR
	if [ "$2" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}

makestock() {
	echo "creating new stock ramdisk archive..."
	if [ -d "$WORKDIR/tmp/ramdisk.stock" ]; then
		rm -rf $WORKDIR/tmp/ramdisk.stock
	fi
	if [ -f "$WORKDIR/tmp/ramdisk.stock.cpio.lzma" ]; then
		rm -f $WORKDIR/tmp/ramdisk.stock.cpio.lzma
	fi
	echo "copying source package"
	cp -fr $WORKDIR/ramdisks/${DRPATH}/ramdisk.stock $WORKDIR/tmp/
	cd $WORKDIR/tmp/ramdisk.stock/
	echo "packing destination package"
	find . | cpio --create --format='newc' > $WORKDIR/tmp/ramdisk.stock.cpio
	if [ "$1" = "yes" ]; then
		lzma -e -4 $WORKDIR/tmp/ramdisk.stock.cpio
	fi
	cd $WORKDIR
	if [ "$2" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}

compiletwrp() {
	cd $WORKDIR/src/cyanogen/$REPO/twrp/android/system
	rm -rf out/target/product/${CODENAME}
	echo "repo sync?"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		repo sync
	fi
	source build/envsetup.sh
	if [ "$CODENAME" = "aoba" -o "$CODENAME" = "hikari" -o "$CODENAME" = "nozomi" ]; then
	curl --create-dirs -L -o .repo/local_manifests/local_manifest.xml -O -L https://raw.githubusercontent.com/olivieer/cm-nozomi/cm-11.0/sony_fuji.xml;repo sync;source build/envsetup.sh;lunch ${CODENAME}
	else
 	breakfast ${CODENAME}
	export USE_CCACHE=1
	time make -j5 recoveryimage
	if [ "$1" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}

compilephilz() {
	cd $WORKDIR/src/cyanogen/$REPO/philz/android/system
	rm -rf out/target/product/${CODENAME}
	echo "repo sync?"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		repo sync
	fi
	source build/envsetup.sh
	if [ "$CODENAME" = "aoba" -o "$CODENAME" = "hikari" -o "$CODENAME" = "nozomi" ]; then
	curl --create-dirs -L -o .repo/local_manifests/local_manifest.xml -O -L https://raw.githubusercontent.com/olivieer/cm-nozomi/cm-11.0/sony_fuji.xml;repo sync;source build/envsetup.sh;lunch ${CODENAME}
	else
	breakfast ${CODENAME}
	export USE_CCACHE=1
	time make -j5 recoveryimage
	if [ "$1" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}

compilecwm() {
	cd $WORKDIR/src/cyanogen/$REPO/cwm/android/system
	rm -rf out/target/product/${CODENAME}
	echo "repo sync?"
	read answer
	if [ "$answer" = "y" -o "$answer" = "Y" ]; then
		repo sync
	fi
	source build/envsetup.sh
	if [ "$CODENAME" = "aoba" -o "$CODENAME" = "hikari" -o "$CODENAME" = "nozomi" ]; then
	curl --create-dirs -L -o .repo/local_manifests/local_manifest.xml -O -L https://raw.githubusercontent.com/olivieer/cm-nozomi/cm-11.0/sony_fuji.xml;repo sync;source build/envsetup.sh;lunch ${CODENAME}
	else
	breakfast ${CODENAME}
	export USE_CCACHE=1
	time make -j5 recoveryimage
	if [ "$1" = "auto" ]; then
		sleep 2
	else
        	echo "Press enter to return to the recovery menu!"
        	read
	fi
}
