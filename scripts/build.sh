#!/bin/bash

cleanuptmp() {
	echo "cleaning up..."
	rm -rf $WORKDIR/.tmp/*
}

cleanupout() {
	echo "removing previous ${LABEL} builds..."
	rm -f $WORKDIR/out/${LABEL}-$1*
}

copysource() {
	# Copy base packages to tmp
	cp -r $WORKDIR/includes/* $WORKDIR/.tmp/
}

doall() {
	if [ "$1" = "single" ]; then
		source $WORKDIR/scripts/recovery.sh
		source $WORKDIR/scripts/build.sh
	fi
	cleanuptmp
	cleanupout lockeddualrecovery
	copysource
	copytwrp auto
#	copycwm auto
#	copyphilz auto
	recoverypatcher auto
	maketwrp $PACKRAMDISK auto
#	makecwm $PACKRAMDISK auto
	makephilz $PACKRAMDISK auto
	if [ -d "$WORKDIR/ramdisks/${DRPATH}/ramdisk.stock" ]; then
		makestock $PACKRAMDISK auto
	fi
	if [ "$2" = "combined" ]; then
		packflashableinstaller
	else
		packflashable
		packinstaller
	fi
}

doallkernel() {
	cleanuptmp
	cleanupout XZDRKernel
	copysource
	selectkernel
	unpackkernel auto
	copytwrp auto
#	copycwm auto
#	copyphilz auto
	recoverypatcher auto
	maketwrp $PACKKERNELRAMDISK auto
#	makecwm $PACKKERNELRAMDISK auto
	makephilz $PACKKERNELRAMDISK auto
	patchramdisk auto
	packramdisk auto
	packkernel auto
	packflashablekernel
}

packflashablekernel() {
	cd $WORKDIR/.tmp/
	mkdir -p $WORKDIR/.tmp/flashable/tmp/
	echo "Flashable Kernel: copying files to their locations..."
	cp $WORKDIR/.tmp/$KERNEL.img $WORKDIR/.tmp/flashable/tmp/boot.img
	cp $WORKDIR/src/setversion.sh $WORKDIR/.tmp/flashable/tmp/setversion.sh
	cp $WORKDIR/src/installndrutils.sh $WORKDIR/.tmp/flashable/tmp/installndrutils.sh
	cp $WORKDIR/.tmp/busybox $WORKDIR/.tmp/flashable/tmp/busybox
	cp $WORKDIR/src/kernel-flashkernel.sh $WORKDIR/.tmp/flashable/tmp/flashkernel.sh
	cp $WORKDIR/src/kernel-updater-script $WORKDIR/.tmp/flashable/META-INF/com/google/android/updater-script
	cp $WORKDIR/.tmp/NDRUtils.apk $WORKDIR/.tmp/flashable/tmp/NDRUtils.apk
	echo "version=${MAJOR}.${MINOR}.${REVISION}" > $WORKDIR/.tmp/flashable/tmp/dr.prop
	echo "release=${RELEASE}" >> $WORKDIR/.tmp/flashable/tmp/dr.prop

	cd $WORKDIR/.tmp/flashable
	find . -name ".gitkeep" -exec rm -f {} \;
	echo "Creating flashable zip..."
	zip -r -b /tmp $WORKDIR/out/${LABEL}-XZDRKernel${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip *
	chmod 644 $WORKDIR/out/${LABEL}-XZDRKernel${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip
	zip -T $WORKDIR/out/${LABEL}-XZDRKernel${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip
}

packflashable() {
	cd $WORKDIR/.tmp/
	mkdir -p $WORKDIR/.tmp/flashable/system/bin
	mkdir -p $WORKDIR/.tmp/flashable/tmp
	mkdir -p $WORKDIR/.tmp/flashable/system/xbin
	mkdir -p $WORKDIR/.tmp/flashable/system/.XZDualRecovery/xbin
	mkdir -p $WORKDIR/.tmp/flashable/system/.XZDualRecovery/bin
	echo "Flashable: copying files to their locations..."
	# Flashable
#	cp $WORKDIR/.tmp/recovery.cwm.cpio.lzma $WORKDIR/.tmp/flashable/system/.XZDualRecovery/xbin/recovery.cwm.cpio.lzma
	cp $WORKDIR/.tmp/recovery.philz.cpio.lzma $WORKDIR/.tmp/flashable/system/.XZDualRecovery/xbin/recovery.philz.cpio.lzma
	cp $WORKDIR/.tmp/recovery.twrp.cpio.lzma $WORKDIR/.tmp/flashable/system/.XZDualRecovery/xbin/recovery.twrp.cpio.lzma
	if [ -f "$WORKDIR/.tmp/ramdisk.stock.cpio.lzma" ]; then
		cp $WORKDIR/.tmp/ramdisk.stock.cpio.lzma $WORKDIR/.tmp/flashable/tmp/ramdisk.stock.cpio.lzma
	fi
	cp $WORKDIR/src/installstock.sh $WORKDIR/.tmp/flashable/tmp/installstock.sh
	cp $WORKDIR/src/setversion.sh $WORKDIR/.tmp/flashable/tmp/setversion.sh
	cp $WORKDIR/src/mr.sh $WORKDIR/.tmp/flashable/system/bin/mr
	cp $WORKDIR/src/chargemon.sh $WORKDIR/.tmp/flashable/system/bin/chargemon
	cp $WORKDIR/src/dualrecovery.sh $WORKDIR/.tmp/flashable/system/.XZDualRecovery/xbin/dualrecovery.sh
	cp $WORKDIR/src/rickiller.sh $WORKDIR/.tmp/flashable/system/.XZDualRecovery/xbin/rickiller.sh
	cp $WORKDIR/src/installdisableric.sh $WORKDIR/.tmp/flashable/tmp/installdisableric.sh
	cp $WORKDIR/.tmp/busybox $WORKDIR/.tmp/flashable/system/.XZDualRecovery/xbin/busybox
	cp $WORKDIR/src/backupstockbinaries.sh $WORKDIR/.tmp/flashable/tmp/backupstockbinaries.sh
	cp $WORKDIR/src/updater-script $WORKDIR/.tmp/flashable/META-INF/com/google/android/updater-script
	cp $WORKDIR/.tmp/NDRUtils.apk $WORKDIR/.tmp/flashable/tmp/NDRUtils.apk
	cp $WORKDIR/src/installndrutils.sh $WORKDIR/.tmp/flashable/tmp/installndrutils.sh
	echo "version=${MAJOR}.${MINOR}.${REVISION}" > $WORKDIR/.tmp/flashable/tmp/dr.prop
	echo "release=${RELEASE}" >> $WORKDIR/.tmp/flashable/tmp/dr.prop

	cd $WORKDIR/.tmp/flashable
	find . -name ".gitkeep" -exec rm -f {} \;
	echo "Creating flashable zip..."
	zip -r -b /tmp $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip *
	chmod 644 $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip
	zip -T $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.flashable.zip
}

packinstaller() {
	echo "Installer: copying files to their locations..."
#	cp $WORKDIR/.tmp/recovery.cwm.cpio.lzma $WORKDIR/.tmp/installer/lockeddualrecovery/files/recovery.cwm.cpio.lzma
	cp $WORKDIR/.tmp/recovery.philz.cpio.lzma $WORKDIR/.tmp/installer/lockeddualrecovery/files/recovery.philz.cpio.lzma
	cp $WORKDIR/.tmp/recovery.twrp.cpio.lzma $WORKDIR/.tmp/installer/lockeddualrecovery/files/recovery.twrp.cpio.lzma
	if [ -f "$WORKDIR/.tmp/ramdisk.stock.cpio.lzma" ]; then
		cp $WORKDIR/.tmp/ramdisk.stock.cpio.lzma $WORKDIR/.tmp/installer/lockeddualrecovery/files/ramdisk.stock.cpio.lzma
	fi
	cp $WORKDIR/.tmp/busybox $WORKDIR/.tmp/installer/lockeddualrecovery/files/busybox
	cp $WORKDIR/src/mr.sh $WORKDIR/.tmp/installer/lockeddualrecovery/files/mr.sh
	cp $WORKDIR/src/chargemon.sh $WORKDIR/.tmp/installer/lockeddualrecovery/files/chargemon.sh
	cp $WORKDIR/src/dualrecovery.sh $WORKDIR/.tmp/installer/lockeddualrecovery/files/dualrecovery.sh
	cp $WORKDIR/src/rickiller.sh $WORKDIR/.tmp/installer/lockeddualrecovery/files/rickiller.sh
	cp $WORKDIR/src/installrecovery.sh $WORKDIR/.tmp/installer/lockeddualrecovery/files/installrecovery.sh
	cp $WORKDIR/src/install.bat $WORKDIR/.tmp/installer/lockeddualrecovery/install.bat
	cp $WORKDIR/src/install.sh $WORKDIR/.tmp/installer/lockeddualrecovery/install.sh
	echo "version=${MAJOR}.${MINOR}.${REVISION}" > $WORKDIR/.tmp/installer/lockeddualrecovery/files/dr.prop
	echo "release=${RELEASE}" >> $WORKDIR/.tmp/installer/lockeddualrecovery/files/dr.prop

	cd $WORKDIR/.tmp/installer/
	find . -name ".gitkeep" -exec rm -f {} \;
	echo "Creating installer zip..."
	zip -r -b /tmp $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.installer.zip *
	chmod 644 $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.installer.zip
	zip -T $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.installer.zip
}

packflashableinstaller() {
	# combined flashable and installer
	cd $WORKDIR/.tmp/
	mkdir -p $WORKDIR/.tmp/combined/system/bin
	mkdir -p $WORKDIR/.tmp/combined/tmp
	mkdir -p $WORKDIR/.tmp/combined/system/xbin
	mkdir -p $WORKDIR/.tmp/combined/system/.XZDualRecovery/xbin
	mkdir -p $WORKDIR/.tmp/combined/system/.XZDualRecovery/bin

	echo "Flashable installer: copying files to their locations..."
#	cp $WORKDIR/.tmp/recovery.cwm.cpio.lzma $WORKDIR/.tmp/combined/system/.XZDualRecovery/xbin/recovery.cwm.cpio.lzma
	cp $WORKDIR/.tmp/recovery.philz.cpio.lzma $WORKDIR/.tmp/combined/system/.XZDualRecovery/xbin/recovery.philz.cpio.lzma
	cp $WORKDIR/.tmp/recovery.twrp.cpio.lzma $WORKDIR/.tmp/combined/system/.XZDualRecovery/xbin/recovery.twrp.cpio.lzma
	if [ -f "$WORKDIR/.tmp/ramdisk.stock.cpio.lzma" ]; then
		cp $WORKDIR/.tmp/ramdisk.stock.cpio.lzma $WORKDIR/.tmp/combined/tmp/ramdisk.stock.cpio.lzma
	fi
	cp $WORKDIR/src/installstock.sh $WORKDIR/.tmp/combined/tmp/installstock.sh
	cp $WORKDIR/src/setversion.sh $WORKDIR/.tmp/combined/tmp/setversion.sh
	cp $WORKDIR/src/mr.sh $WORKDIR/.tmp/combined/system/bin/mr
	cp $WORKDIR/src/chargemon.sh $WORKDIR/.tmp/combined/system/bin/chargemon
	cp $WORKDIR/src/dualrecovery.sh $WORKDIR/.tmp/combined/system/.XZDualRecovery/xbin/dualrecovery.sh
	cp $WORKDIR/src/rickiller.sh $WORKDIR/.tmp/combined/system/.XZDualRecovery/xbin/rickiller.sh
	cp $WORKDIR/src/installdisableric.sh $WORKDIR/.tmp/combined/tmp/installdisableric.sh
	cp $WORKDIR/.tmp/busybox $WORKDIR/.tmp/combined/system/.XZDualRecovery/xbin/busybox
	cp $WORKDIR/src/backupstockbinaries.sh $WORKDIR/.tmp/combined/tmp/backupstockbinaries.sh
	cp $WORKDIR/src/updater-script $WORKDIR/.tmp/combined/META-INF/com/google/android/updater-script
	cp $WORKDIR/.tmp/NDRUtils.apk $WORKDIR/.tmp/combined/tmp/NDRUtils.apk
	cp $WORKDIR/src/installndrutils.sh $WORKDIR/.tmp/combined/tmp/installndrutils.sh
	cp $WORKDIR/src/installrecovery.sh $WORKDIR/.tmp/combined/tmp/installrecovery.sh
	cp $WORKDIR/src/combined.bat $WORKDIR/.tmp/combined/install.bat
	cp $WORKDIR/src/combined.sh $WORKDIR/.tmp/combined/install.sh

	echo "version=${MAJOR}.${MINOR}.${REVISION}" > $WORKDIR/.tmp/combined/tmp/dr.prop
	echo "release=${RELEASE}" >> $WORKDIR/.tmp/combined/tmp/dr.prop

	cd $WORKDIR/.tmp/combined
	find . -name ".gitkeep" -exec rm -f {} \;
	echo "Creating flashable installer zip..."
	zip -r -b /tmp $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.combined.zip *
	chmod 644 $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.combined.zip
	zip -T $WORKDIR/out/${LABEL}-lockeddualrecovery${MAJOR}.${MINOR}.${REVISION}-${RELEASE}.combined.zip

}
